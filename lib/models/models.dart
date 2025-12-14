class OdooConfig {
  final String url;
  final String database;
  final String email;
  final String password;
  final int port;

  OdooConfig({
    required this.url,
    required this.database,
    required this.email,
    required this.password,
    required this.port,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'database': database,
        'email': email,
        'password': password,
        'port': port,
      };

  factory OdooConfig.fromJson(Map<String, dynamic> json) => OdooConfig(
        url: json['url'],
        database: json['database'],
        email: json['email'],
        password: json['password'],
        port: json['port'],
      );

  String get baseUrl {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }

  String get fullUrl {
    if (port != 443 && port != 80) {
      return '$baseUrl:$port';
    }
    return baseUrl;
  }
}

class Attendance {
  final int? id;
  final int employeeId;
  final DateTime checkIn;
  final DateTime? checkOut;

  Attendance({
    this.id,
    required this.employeeId,
    required this.checkIn,
    this.checkOut,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'],
        employeeId: json['employee_id'] is List
            ? json['employee_id'][0]
            : json['employee_id'],
        checkIn: DateTime.parse(json['check_in']),
        checkOut:
            json['check_out'] != null ? DateTime.parse(json['check_out']) : null,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'check_in': checkIn.toIso8601String(),
        if (checkOut != null) 'check_out': checkOut!.toIso8601String(),
      };

  bool get isOpen => checkOut == null;
}
