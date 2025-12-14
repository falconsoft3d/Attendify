import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _configKey = 'odoo_config';
  static const _storage = FlutterSecureStorage();

  /// Guardar configuración de Odoo
  static Future<void> saveConfig(OdooConfig config) async {
    final configJson = jsonEncode(config.toJson());
    await _storage.write(key: _configKey, value: configJson);
  }

  /// Obtener configuración guardada
  static Future<OdooConfig?> getConfig() async {
    final configJson = await _storage.read(key: _configKey);
    if (configJson != null) {
      return OdooConfig.fromJson(jsonDecode(configJson));
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
