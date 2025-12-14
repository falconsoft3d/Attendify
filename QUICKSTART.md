# Guía de Inicio Rápido - Attendify

## 🎯 Pasos para ejecutar la aplicación

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Verificar dispositivos disponibles
```bash
flutter devices
```

### 3. Ejecutar en simulador iOS (recomendado para desarrollo)
```bash
flutter run
```

O específicamente en un simulador:
```bash
flutter run -d "iPhone 15 Pro"
```

### 4. Ejecutar en dispositivo físico
1. Conecta tu iPhone con USB
2. Confía en el dispositivo desde tu Mac
3. Ejecuta:
```bash
flutter run
```

## 🔧 Configuración de Odoo para pruebas

### Datos de ejemplo para la configuración:

- **URL**: `tu-empresa.odoo.com` (sin http:// ni https://)
- **Puerto**: `443` (para HTTPS) o `8069` (si usas Odoo local)
- **Base de datos**: El nombre de tu base de datos en Odoo
- **Email**: Tu correo de usuario en Odoo
- **Contraseña**: Tu contraseña de Odoo

### Verificar requisitos en Odoo:

1. Ve a Ajustes → Usuarios → Tu usuario
2. Verifica que tengas un "Empleado relacionado"
3. Si no tienes, ve a Empleados y crea uno vinculado a tu usuario
4. Asegúrate de tener el módulo "Asistencias" instalado

## 🐛 Solución de problemas comunes

### Error: "No se encontró empleado asociado"
**Solución**: En Odoo, ve a Empleados y vincula tu usuario a un empleado.

### Error: "Error de autenticación"
**Solución**: Verifica que:
- La URL sea correcta (sin http:// ni https://)
- El puerto sea el correcto
- El nombre de la base de datos sea exacto
- Las credenciales sean correctas

### Error: "No module named 'hr_attendance'"
**Solución**: Instala el módulo de Asistencias en tu instancia de Odoo:
1. Ve a Aplicaciones
2. Busca "Asistencias" o "Attendance"
3. Haz clic en "Instalar"

### La app no se conecta
**Solución**: 
- Verifica que tu Mac/iPhone tenga conexión a Internet
- Si usas Odoo local, asegúrate de estar en la misma red
- Verifica que el firewall no bloquee la conexión

## 📱 Compilar para producción

### Compilar IPA para distribución:
```bash
flutter build ios --release
```

### Compilar para App Store:
1. Configura tu cuenta de Apple Developer en Xcode
2. Abre el proyecto en Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
3. Configura el equipo de desarrollo y el Bundle ID
4. Compila desde Xcode o usa:
   ```bash
   flutter build ipa
   ```

## 📊 Estructura de archivos creados

```
Attendify/
├── lib/
│   ├── main.dart               # Punto de entrada
│   ├── models/
│   │   └── models.dart         # Modelos de datos
│   ├── services/
│   │   ├── odoo_service.dart   # Comunicación con Odoo
│   │   └── storage_service.dart# Almacenamiento local
│   └── screens/
│       ├── config_screen.dart  # Configuración inicial
│       └── home_screen.dart    # Pantalla principal
├── ios/                        # Configuración iOS
├── pubspec.yaml               # Dependencias
└── README.md                  # Documentación completa
```

## 🎨 Personalización

### Cambiar colores principales:
Edita [lib/main.dart](lib/main.dart), línea 18-20:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.blue, // Cambia este color
  brightness: Brightness.light,
),
```

### Cambiar el nombre de la app:
1. [pubspec.yaml](pubspec.yaml) - línea 1
2. [ios/Runner/Info.plist](ios/Runner/Info.plist) - CFBundleDisplayName

## 📚 Recursos adicionales

- [Documentación de Flutter](https://flutter.dev/docs)
- [Documentación de Odoo API](https://www.odoo.com/documentation/16.0/developer/api/external_api.html)
- [JSON-RPC en Odoo](https://www.odoo.com/documentation/16.0/developer/howtos/web_services.html)

## 💡 Consejos

- Usa Hot Reload (`r` en la terminal) durante el desarrollo para ver cambios instantáneamente
- Usa Hot Restart (`R`) si los cambios no se reflejan con Hot Reload
- Revisa los logs en la terminal para identificar errores
- Usa el depurador de Flutter DevTools para inspeccionar la app

---

¿Necesitas ayuda? Revisa el [README.md](README.md) completo o crea un issue en el repositorio.
