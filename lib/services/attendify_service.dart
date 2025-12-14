import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class AttendifyService {
  AttendifyConfig? _config;
  String? _sessionCookie;
  EmpleadoInfo? _empleado;
  final _client = http.Client();

  // Singleton pattern
  static final AttendifyService _instance = AttendifyService._internal();
  factory AttendifyService() => _instance;
  AttendifyService._internal();

  void setConfig(AttendifyConfig config) {
    _config = config;
  }

  AttendifyConfig? get config => _config;
  EmpleadoInfo? get empleado => _empleado;
  bool get isAuthenticated => _sessionCookie != null && _empleado != null;

  /// Autenticar con OpenAttendify usando cookies
  Future<bool> authenticate() async {
    if (_config == null) {
      throw Exception('Configuración no establecida');
    }

    try {
      final url = Uri.parse('${_config!.url}/api/empleado/login');
      
      final body = jsonEncode({
        'codigo': _config!.codigo,
        'password': _config!.password,
      });

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        if (decoded['success'] == true) {
          // Guardar cookie de sesión
          final cookies = response.headers['set-cookie'];
          if (cookies != null) {
            _sessionCookie = _extractSessionCookie(cookies);
          }
          
          _empleado = EmpleadoInfo.fromJson(decoded['empleado']);
          return true;
        } else {
          final message = decoded['message'] ?? 'Error desconocido';
          print('Error en autenticación: $message');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error de autenticación: $e');
      return false;
    }
  }

  /// Extraer cookie de sesión del header Set-Cookie
  String _extractSessionCookie(String setCookieHeader) {
    final cookies = setCookieHeader.split(',');
    for (var cookie in cookies) {
      final parts = cookie.split(';');
      if (parts.isNotEmpty) {
        return parts[0].trim();
      }
    }
    return setCookieHeader.split(';')[0];
  }

  /// Obtener headers con cookie de sesión
  Map<String, String> _getHeaders({bool includeContentType = false}) {
    final headers = <String, String>{};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  /// Verificar si hay una asistencia abierta
  Future<Attendance?> getOpenAttendance() async {
    if (!isAuthenticated) {
      throw Exception('No autenticado');
    }

    try {
      final url = Uri.parse('${_config!.url}/api/empleado/asistencia')
          .replace(queryParameters: {'tipo': 'activa'});

      final response = await _client.get(
        url,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        if (decoded['asistencia'] != null) {
          return Attendance(
            id: decoded['asistencia']['id'],
            empleadoId: _empleado!.id,
            checkIn: DateTime.parse(decoded['asistencia']['checkIn']),
            checkOut: decoded['asistencia']['checkOut'] != null
                ? DateTime.parse(decoded['asistencia']['checkOut'])
                : null,
            tipo: 'entrada',
          );
        }
      } else if (response.statusCode == 400) {
        // El servidor devuelve 400 cuando no hay asistencia activa
        final decoded = jsonDecode(response.body);
        if (decoded['error'] != null && decoded['error'].toString().contains('No tienes una asistencia activa')) {
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error al obtener asistencia abierta: $e');
      rethrow;
    }
  }

  /// Registrar entrada (check-in)
  Future<Attendance> checkIn() async {
    if (!isAuthenticated) {
      throw Exception('No autenticado');
    }

    try {
      final url = Uri.parse('${_config!.url}/api/empleado/asistencia');

      final response = await _client.post(
        url,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return Attendance(
          id: decoded['asistencia']['id'],
          empleadoId: _empleado!.id,
          checkIn: DateTime.parse(decoded['asistencia']['checkIn']),
          tipo: 'entrada',
        );
      }
      throw Exception('Error al registrar entrada: ${response.statusCode}');
    } catch (e) {
      print('Error al registrar entrada: $e');
      rethrow;
    }
  }

  /// Registrar salida (check-out)
  Future<bool> checkOut() async {
    if (!isAuthenticated) {
      throw Exception('No autenticado');
    }

    try {
      final url = Uri.parse('${_config!.url}/api/empleado/asistencia');

      final request = http.Request('PATCH', url)
        ..headers.addAll(_getHeaders());
      
      final streamedResponse = await _client.send(request);
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        
        // Verificar si existe el campo 'success' o si la respuesta es exitosa
        if (decoded['success'] == true || decoded['asistencia'] != null) {
          return true;
        }
      } else if (streamedResponse.statusCode == 400) {
        // Error 400: No hay asistencia activa
        return false;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtener historial de asistencias
  Future<List<Attendance>> getAttendanceHistory({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int limit = 50,
  }) async {
    if (!isAuthenticated) {
      throw Exception('No autenticado');
    }

    try {
      final url = Uri.parse('${_config!.url}/api/empleado/asistencia');

      final response = await _client.get(
        url,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> asistencias = decoded['asistencias'] ?? [];
        
        return asistencias
            .take(limit)
            .map((json) => Attendance(
                  id: json['id'],
                  empleadoId: _empleado!.id,
                  checkIn: DateTime.parse(json['checkIn']),
                  checkOut: json['checkOut'] != null
                      ? DateTime.parse(json['checkOut'])
                      : null,
                  tipo: 'entrada',
                ))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener historial de asistencias: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      if (_config != null && _sessionCookie != null) {
        final url = Uri.parse('${_config!.url}/api/empleado/logout');
        await _client.post(
          url,
          headers: _getHeaders(),
        ).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      print('Error al cerrar sesión en servidor: $e');
    } finally {
      _sessionCookie = null;
      _empleado = null;
    }
  }
}
