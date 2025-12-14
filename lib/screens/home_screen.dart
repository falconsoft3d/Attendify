import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/attendify_service.dart';
import 'config_screen.dart';
import 'attendance_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _attendifyService = AttendifyService();
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
      // Obtener nombre del empleado
      final empleado = _attendifyService.empleado;
      if (empleado != null) {
        _userName = empleado.nombre;
      }

      // Verificar si hay asistencia abierta
      final attendance = await _attendifyService.getOpenAttendance();
      
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
      final attendance = await _attendifyService.checkIn();
      
      if (mounted) {
        setState(() {
          _currentAttendance = attendance;
          _isLoading = false;
        });
        _showSuccess('¡Entrada registrada correctamente!');
        
        // Recargar el estado para asegurar sincronización
        await _loadAttendanceStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error al registrar entrada: ${e.toString()}');
      }
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isLoading = true);

    try {
      final success = await _attendifyService.checkOut();
      
      if (mounted) {
        if (success) {
          setState(() {
            _currentAttendance = null;
            _isLoading = false;
          });
          _showSuccess('¡Salida registrada correctamente!');
          
          // Recargar el estado sin mostrar mensajes adicionales
          await _loadAttendanceStatus();
        } else {
          // Si falla, recargar y solo mostrar error si realmente falló
          await _loadAttendanceStatus();
          
          setState(() => _isLoading = false);
          _showError('Error al registrar salida. Intenta nuevamente.');
        }
      }
    } catch (e) {
      if (mounted) {
        await _loadAttendanceStatus();
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
      // Solo limpiar la sesión, no los datos guardados
      _attendifyService.logout();
      
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Attendify',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de Asistencias'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AttendanceHistoryScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
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

                    const SizedBox(height: 40),

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
