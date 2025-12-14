import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/odoo_service.dart';
import '../services/storage_service.dart';
import 'config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _odooService = OdooService();
  Attendance? _currentAttendance;
  bool _isLoading = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadAttendanceStatus();
  }

  Future<void> _loadAttendanceStatus() async {
    setState(() => _isLoading = true);

    try {
      // Obtener configuración y nombre de usuario
      final config = await StorageService.getConfig();
      if (config != null) {
        _userName = config.email.split('@')[0];
      }

      // Verificar si hay asistencia abierta
      final attendance = await _odooService.getOpenAttendance();
      
      if (mounted) {
        setState(() {
          _currentAttendance = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error al cargar estado: ${e.toString()}');
      }
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isLoading = true);

    try {
      final attendance = await _odooService.checkIn();
      
      if (mounted) {
        setState(() {
          _currentAttendance = attendance;
          _isLoading = false;
        });
        _showSuccess('¡Entrada registrada correctamente!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error al registrar entrada: ${e.toString()}');
      }
    }
  }

  Future<void> _handleCheckOut() async {
    if (_currentAttendance?.id == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await _odooService.checkOut(_currentAttendance!.id!);
      
      if (mounted) {
        if (success) {
          setState(() {
            _currentAttendance = null;
            _isLoading = false;
          });
          _showSuccess('¡Salida registrada correctamente!');
        } else {
          setState(() => _isLoading = false);
          _showError('Error al registrar salida');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error al registrar salida: ${e.toString()}');
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearConfig();
      _odooService.logout();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ConfigScreen()),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _calculateDuration(DateTime checkIn) {
    final duration = DateTime.now().difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAttendanceStatus,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Saludo
                    Text(
                      '¡Hola, ${_userName ?? "Usuario"}!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 40),

                    // Estado actual
                    if (_currentAttendance != null) ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 48,
                                color: Colors.green[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'En el trabajo',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Entrada: ${_formatDateTime(_currentAttendance!.checkIn)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tiempo transcurrido: ${_calculateDuration(_currentAttendance!.checkIn)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 48,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Fuera del trabajo',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No hay asistencia activa',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Botón principal
                    SizedBox(
                      height: 180,
                      child: ElevatedButton(
                        onPressed: _currentAttendance == null
                            ? _handleCheckIn
                            : _handleCheckOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentAttendance == null
                              ? Colors.green
                              : Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentAttendance == null
                                  ? Icons.login
                                  : Icons.logout,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentAttendance == null
                                  ? 'REGISTRAR ENTRADA'
                                  : 'REGISTRAR SALIDA',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
