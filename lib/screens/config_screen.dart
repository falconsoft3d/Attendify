import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/attendify_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController(text: 'https://openattendify.xyz');
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberData = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final config = await StorageService.getConfig();
    if (config != null) {
      setState(() {
        _urlController.text = config.url;
        _codigoController.text = config.codigo;
        _passwordController.text = config.password;
        _rememberData = true;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _codigoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveAndConnect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final config = AttendifyConfig(
        url: _urlController.text.trim(),
        codigo: _codigoController.text.trim(),
        password: _passwordController.text,
      );

      // Guardar configuración solo si el usuario marcó "Recordar"
      if (_rememberData) {
        await StorageService.saveConfig(config);
      } else {
        // Si no está marcado, limpiar datos guardados
        await StorageService.clearConfig();
      }
      
      // Configurar servicio de Attendify
      final attendifyService = AttendifyService();
      attendifyService.setConfig(config);

      // Intentar autenticar
      final authenticated = await attendifyService.authenticate();

      if (!mounted) return;

      if (authenticated) {
        // Navegar a la pantalla principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showError('Error de autenticación. Verifica tus credenciales.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo y títulos en la misma fila
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo con bordes redondeados
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Títulos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuración',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ingresa tus datos de acceso',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Campo URL
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'URL del Servidor',
                    hintText: 'https://openattendify.xyz',
                    prefixIcon: const Icon(Icons.cloud_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la URL';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'La URL debe comenzar con http:// o https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Campo Código/DNI
                TextFormField(
                  controller: _codigoController,
                  decoration: InputDecoration(
                    labelText: 'Código/DNI',
                    hintText: '10001',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu código o DNI';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Campo Contraseña
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Checkbox Recordar datos
                CheckboxListTile(
                  value: _rememberData,
                  onChanged: (value) {
                    setState(() {
                      _rememberData = value ?? false;
                    });
                  },
                  title: const Text('Recordar datos'),
                  subtitle: const Text('Guardar configuración para próximos inicios'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),
                
                // Botón de guardar
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndConnect,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Conectar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
