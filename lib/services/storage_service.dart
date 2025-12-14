import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

class StorageService {
  static const String _configKey = 'attendify_config';
  static const _storage = FlutterSecureStorage();

  /// Guardar configuración de Attendify
  static Future<void> saveConfig(AttendifyConfig config) async {
    final configJson = jsonEncode(config.toJson());
    await _storage.write(key: _configKey, value: configJson);
  }

  /// Obtener configuración guardada
  static Future<AttendifyConfig?> getConfig() async {
    final configJson = await _storage.read(key: _configKey);
    if (configJson != null) {
      return AttendifyConfig.fromJson(jsonDecode(configJson));
    }
    return null;
  }

  /// Verificar si existe configuración
  static Future<bool> hasConfig() async {
    final config = await getConfig();
    return config != null;
  }

  /// Eliminar configuración
  static Future<void> clearConfig() async {
    await _storage.delete(key: _configKey);
  }
}
