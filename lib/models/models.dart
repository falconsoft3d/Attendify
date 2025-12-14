class AttendifyConfig {
  final String url;
  final String codigo;
  final String password;

  AttendifyConfig({
    required this.url,
    required this.codigo,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'codigo': codigo,
        'password': password,
      };

  factory AttendifyConfig.fromJson(Map<String, dynamic> json) => AttendifyConfig(
        url: json['url'] ?? 'https://openattendify.xyz',
        codigo: json['codigo'],
        password: json['password'],
      );
}

class Attendance {
  final String? id;
  final String empleadoId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String tipo;

  Attendance({
    this.id,
    required this.empleadoId,
    required this.checkIn,
    this.checkOut,
    required this.tipo,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'],
        empleadoId: json['empleadoId'],
        checkIn: DateTime.parse(json['checkIn'] ?? json['entrada']),
        checkOut: json['checkOut'] != null || json['salida'] != null
            ? DateTime.parse(json['checkOut'] ?? json['salida'])
            : null,
        tipo: json['tipo'] ?? 'entrada',
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'empleadoId': empleadoId,
        'checkIn': checkIn.toIso8601String(),
        if (checkOut != null) 'checkOut': checkOut!.toIso8601String(),
        'tipo': tipo,
      };

  bool get isOpen => checkOut == null;
}

class EmpleadoInfo {
  final String id;
  final String codigo;
  final String nombre;
  final String apellido;
  final String? empresa;

  EmpleadoInfo({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.apellido,
    this.empresa,
  });

  factory EmpleadoInfo.fromJson(Map<String, dynamic> json) => EmpleadoInfo(
        id: json['id'],
        codigo: json['codigo'],
        nombre: json['nombre'],
        apellido: json['apellido'],
        empresa: json['empresa']?.toString(),
      );

  String get nombreCompleto => '$nombre $apellido';
}
