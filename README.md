# Attendify 📱

Aplicación Flutter para iOS que permite registrar asistencias (entradas y salidas) en Odoo de manera fácil y rápida mediante JSON-RPC.

## ✨ Características

- 🔐 **Configuración inicial**: Guarda de forma segura las credenciales de conexión a Odoo
- ⏱️ **Registro de asistencias**: Registra entradas y salidas con un solo toque
- 🔄 **Sincronización automática**: Detecta automáticamente si hay una asistencia abierta
- 🎨 **Interfaz moderna**: Diseño limpio y fácil de usar
- 🔒 **Almacenamiento seguro**: Las credenciales se guardan de forma segura usando Flutter Secure Storage

## 📋 Requisitos previos

- Flutter SDK (>=3.0.0)
- Xcode (para desarrollo en iOS)
- Instancia de Odoo con el módulo `hr.attendance` instalado
- Usuario de Odoo con permisos para registrar asistencias
- El usuario debe estar asociado a un empleado en Odoo

## 🚀 Instalación

1. **Clona el repositorio**
   ```bash
   cd "Attendify"
   ```

2. **Instala las dependencias**
   ```bash
   flutter pub get
   ```

3. **Configura el proyecto para iOS**
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Ejecuta la aplicación**
   ```bash
   flutter run
   ```

## 📱 Uso

### Primera vez (Configuración)

1. Al abrir la app por primera vez, verás la pantalla de configuración
2. Ingresa los siguientes datos:
   - **URL de Odoo**: La URL de tu instancia (ej: `miempresa.odoo.com`)
   - **Puerto**: Puerto de conexión (por defecto: `443` para HTTPS)
   - **Nombre de la base de datos**: El nombre de tu base de datos en Odoo
   - **Email**: Tu correo de usuario en Odoo
   - **Contraseña**: Tu contraseña de Odoo

3. Presiona "Conectar" para guardar y autenticar

### Registro de asistencias

- **Registrar entrada**: Si no hay asistencia activa, verás un botón verde grande "REGISTRAR ENTRADA"
- **Registrar salida**: Si ya registraste entrada, verás un botón rojo "REGISTRAR SALIDA"
- La app muestra el tiempo transcurrido desde tu entrada
- Usa el botón de actualizar (🔄) para sincronizar el estado con Odoo

### Cerrar sesión

- Presiona el ícono de cerrar sesión (⎋) en la parte superior derecha
- Confirma la acción
- Esto borrará las credenciales guardadas y volverás a la pantalla de configuración

## 🏗️ Estructura del proyecto

```
lib/
├── main.dart                    # Punto de entrada de la app
├── models/
│   └── models.dart             # Modelos de datos (OdooConfig, Attendance)
├── services/
│   ├── odoo_service.dart       # Servicio de comunicación con Odoo
│   └── storage_service.dart    # Servicio de almacenamiento local
└── screens/
    ├── config_screen.dart      # Pantalla de configuración
    └── home_screen.dart        # Pantalla principal de asistencias
```

## 🔧 Configuración de Odoo

### Requisitos en Odoo

1. **Módulo instalado**: Asegúrate de tener instalado el módulo `hr_attendance`
2. **Usuario y empleado**: 
   - Tu usuario debe estar vinculado a un empleado
   - El empleado debe tener permisos para registrar asistencias
3. **API habilitada**: Odoo debe permitir conexiones JSON-RPC

### Permisos necesarios

El usuario necesita al menos estos permisos:
- Lectura y escritura en `hr.attendance`
- Lectura en `hr.employee`

## 🛠️ Tecnologías utilizadas

- **Flutter**: Framework de desarrollo
- **http**: Para comunicación JSON-RPC con Odoo
- **flutter_secure_storage**: Almacenamiento seguro de credenciales
- **shared_preferences**: Preferencias de la aplicación
- **intl**: Formateo de fechas en español

## 📝 Notas importantes

- Las credenciales se almacenan de forma segura en el dispositivo
- La aplicación requiere conexión a Internet para funcionar
- Asegúrate de que tu instancia de Odoo sea accesible desde el dispositivo móvil
- Los registros se sincronizan inmediatamente con Odoo

## 🐛 Solución de problemas

### Error de autenticación
- Verifica que la URL, puerto y nombre de base de datos sean correctos
- Asegúrate de que tu usuario y contraseña sean válidos
- Confirma que la instancia de Odoo sea accesible

### No se puede registrar asistencia
- Verifica que tu usuario esté vinculado a un empleado en Odoo
- Confirma que tengas los permisos necesarios
- Revisa que el módulo `hr_attendance` esté instalado

### Error de conexión
- Verifica tu conexión a Internet
- Asegúrate de que el puerto sea correcto (443 para HTTPS, 80 para HTTP)
- Confirma que tu firewall o VPN no bloquee la conexión

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

## 👨‍💻 Desarrollo

Para contribuir o modificar la aplicación:

1. Haz un fork del proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Si encuentras algún problema o tienes sugerencias, por favor crea un issue en el repositorio.

---

Desarrollado con ❤️ usando Flutter
