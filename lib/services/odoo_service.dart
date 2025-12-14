import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';

class OdooService {
  OdooConfig? _config;
  int? _uid;
  String? _sessionId;

  // Singleton pattern
  static final OdooService _instance = OdooService._internal();
  factory OdooService() => _instance;
  OdooService._internal();

  void setConfig(OdooConfig config) {
    _config = config;
  }

  OdooConfig? get config => _config;
  bool get isAuthenticated => _uid != null;

  /// Autenticar con Odoo usando JSON-RPC
  Future<bool> authenticate() async {
    if (_config == null) {
      throw Exception('Configuración no establecida');
    }

    try {
      final response = await _jsonRpcCall(
        '/web/session/authenticate',
        {
          'db': _config!.database,
          'login': _config!.email,
          'password': _config!.password,
        },
      );

      if (response['result'] != null && response['result']['uid'] != null) {
        _uid = response['result']['uid'];
        _sessionId = response['result']['session_id'];
        return true;
      }
      return false;
    } catch (e) {
      print('Error de autenticación: $e');
      return false;
    }
  }

  /// Verificar si hay una asistencia abierta
  Future<Attendance?> getOpenAttendance() async {
    if (_uid == null) {
      throw Exception('No autenticado');
    }

    try {
      // Primero obtener el ID del empleado asociado al usuario
      final employeeId = await _getEmployeeId();
      if (employeeId == null) {
        throw Exception('No se encontró empleado asociado al usuario');
      }

      // Buscar asistencias abiertas
      final response = await _callOdooMethod(
        'hr.attendance',
        'search_read',
        [
          [
            ['employee_id', '=', employeeId],
            ['check_out', '=', false],
          ]
        ],
        {
          'fields': ['id', 'employee_id', 'check_in', 'check_out'],
          'limit': 1,
        },
      );

      if (response['result'] != null && 
          response['result'] is List && 
          (response['result'] as List).isNotEmpty) {
        return Attendance.fromJson(response['result'][0]);
      }
      return null;
    } catch (e) {
      print('Error al obtener asistencia abierta: $e');
      rethrow;
    }
  }

  /// Registrar entrada (check-in)
  Future<Attendance> checkIn() async {
    if (_uid == null) {
      throw Exception('No autenticado');
    }

    try {
      final employeeId = await _getEmployeeId();
      if (employeeId == null) {
        throw Exception('No se encontró empleado asociado al usuario');
      }

      final now = DateTime.now();
      final response = await _callOdooMethod(
        'hr.attendance',
        'create',
        [
          {
            'employee_id': employeeId,
            'check_in': now.toUtc().toIso8601String(),
          }
        ],
        {},
      );

      if (response['result'] != null) {
        return Attendance(
          id: response['result'],
          employeeId: employeeId,
          checkIn: now,
        );
      }
      throw Exception('Error al crear asistencia');
    } catch (e) {
      print('Error al registrar entrada: $e');
      rethrow;
    }
  }

  /// Registrar salida (check-out)
  Future<bool> checkOut(int attendanceId) async {
    if (_uid == null) {
      throw Exception('No autenticado');
    }

    try {
      final now = DateTime.now();
      final response = await _callOdooMethod(
        'hr.attendance',
        'write',
        [
          [attendanceId],
          {
            'check_out': now.toUtc().toIso8601String(),
          }
        ],
        {},
      );

      return response['result'] == true;
    } catch (e) {
      print('Error al registrar salida: $e');
      rethrow;
    }
  }

  /// Obtener el ID del empleado asociado al usuario actual
  Future<int?> _getEmployeeId() async {
    try {
      final response = await _callOdooMethod(
        'hr.employee',
        'search_read',
        [
          [
            ['user_id', '=', _uid]
          ]
        ],
        {
          'fields': ['id'],
          'limit': 1,
        },
      );

      if (response['result'] != null && 
          response['result'] is List && 
          (response['result'] as List).isNotEmpty) {
        return response['result'][0]['id'];
      }
      return null;
    } catch (e) {
      print('Error al obtener ID de empleado: $e');
      return null;
    }
  }

  /// Llamada genérica a método de Odoo
  Future<Map<String, dynamic>> _callOdooMethod(
    String model,
    String method,
    List args,
    Map<String, dynamic> kwargs,
  ) async {
    if (_config == null || _uid == null) {
      throw Exception('No autenticado');
    }

    return await _jsonRpcCall('/web/dataset/call_kw/$model/$method', {
      'model': model,
      'method': method,
      'args': args,
      'kwargs': {
        'context': {'lang': 'es_ES', 'tz': 'America/New_York'},
        ...kwargs,
      },
    });
  }

  /// Llamada JSON-RPC genérica
  Future<Map<String, dynamic>> _jsonRpcCall(
    String endpoint,
    Map<String, dynamic> params,
  ) async {
    if (_config == null) {
      throw Exception('Configuración no establecida');
    }

    final targetUrl = '${_config!.fullUrl}$endpoint';
    
    // En web, usar proxy local para evitar CORS
    final url = kIsWeb 
        ? Uri.parse('http://localhost:8080')
        : Uri.parse(targetUrl);
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Si estamos en web, agregar el header con la URL de destino
    if (kIsWeb) {
      headers['x-target-url'] = targetUrl;
    }
    
    if (_sessionId != null && !kIsWeb) {
      headers['Cookie'] = 'session_id=$_sessionId';
    }

    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'call',
      'params': params,
      'id': DateTime.now().millisecondsSinceEpoch,
    });

    print('Llamando a: ${kIsWeb ? targetUrl + " (via proxy)" : targetUrl}');
    print('Con body: $body');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('Respuesta status: ${response.statusCode}');
      print('Respuesta body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['error'] != null) {
          final errorMsg = decoded['error']['data']?['message'] ?? 
                          decoded['error']['message'] ?? 
                          'Error desconocido';
          throw Exception('Error de Odoo: $errorMsg');
        }
        return decoded;
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error en _jsonRpcCall: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  void logout() {
    _uid = null;
    _sessionId = null;
  }
}
