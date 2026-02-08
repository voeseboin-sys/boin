# Gestión Fábrica - Aplicación Móvil

Aplicación móvil completa para gestión de fábrica con sistema de roles, contabilidad en PYG (Guaraníes Paraguayos) y exportación a PDF.

## Características

### Sistema de Roles (RBAC)
- **Dueño (Admin)**: Acceso total - puede ver "Gastos Personales", "Utilidades", borrar registros y exportar PDFs
- **Vendedor (Staff)**: Solo acceso a "Ventas", "Stock" (solo lectura) y "Registro de Producción"

### Dashboard y Lógica Contable
- **Dinero Total**: Saldo real acumulado (no se resetea)
- **Ventas del Mes**: Acumulado de ingresos brutos mensuales
- **Gastos de Fábrica**: Afectan directamente el "Costo de Producto" del mes en curso
- **Gastos Personales**: Se restan del Dinero Total pero no afectan el costo de producción
- **Costo de Producto Automático**: Calculado como (Gastos de Fábrica / Unidades Fabricadas) del mes actual

### Gestión de Productos y Ventas
- Registro de productos con Precio Mayorista y Minorista
- Módulo de ventas con opción de aplicar DESCUENTO manual antes de confirmar
- Stock arrastra el costo del mes en que fue fabricado (Lógica FIFO)
- Opción de borrar cualquier registro (Solo Dueño)

### Exportación y Persistencia
- Generar Extracto Mensual en PDF con: Balance, Producción y Detalle de Ventas
- Base de datos local robusta con SQLite (Drift)

### Interfaz
- Tema Oscuro (Dark Mode) con acentos en verde esmeralda (#2ecc71)
- Diseño moderno y scannable

## Estructura del Proyecto

```
lib/
├── core/
│   ├── constants.dart      # Constantes y extensiones
│   ├── theme.dart          # Tema oscuro con acentos verdes
│   └── core.dart           # Exportaciones
├── models/
│   ├── usuario.dart        # Modelo de usuario con roles
│   ├── producto.dart       # Modelo de producto
│   ├── venta.dart          # Modelo de venta e items
│   ├── gasto.dart          # Modelo de gastos (fábrica/personal)
│   ├── produccion.dart     # Modelo de producción
│   ├── metricas.dart       # Métricas del dashboard
│   └── models.dart         # Exportaciones
├── providers/
│   ├── auth_provider.dart       # Autenticación y estado de usuario
│   ├── producto_provider.dart   # Estado de productos
│   ├── venta_provider.dart      # Estado de ventas y carrito
│   ├── gasto_provider.dart      # Estado de gastos
│   ├── produccion_provider.dart # Estado de producción
│   ├── metricas_provider.dart   # Métricas y dashboard
│   └── providers.dart           # Exportaciones
├── screens/
│   ├── login_screen.dart        # Pantalla de login
│   ├── dashboard_screen.dart    # Dashboard principal
│   ├── productos_screen.dart    # Gestión de stock
│   ├── ventas_screen.dart       # Historial de ventas
│   ├── nueva_venta_screen.dart  # Nueva venta con carrito
│   ├── produccion_screen.dart   # Registro de producción
│   ├── gastos_screen.dart       # Gestión de gastos
│   └── screens.dart             # Exportaciones
├── services/
│   ├── database.dart       # Base de datos SQLite con Drift
│   ├── pdf_service.dart    # Generación de PDFs
│   └── services.dart       # Exportaciones
├── widgets/
│   ├── metric_card.dart    # Tarjetas de métricas
│   ├── loading_widget.dart # Widgets de carga y estados
│   ├── confirm_dialog.dart # Diálogos de confirmación
│   └── widgets.dart        # Exportaciones
└── main.dart               # Punto de entrada
```

## Credenciales de Prueba

### Dueño (Admin)
- Email: `admin@fabrica.com`
- Password: `admin123`

### Vendedor (Staff)
- Email: `vendedor@fabrica.com`
- Password: `vendedor123`

## Guía de Instalación y Compilación

### Requisitos Previos

1. **Flutter SDK** (versión 3.0.0 o superior)
   ```bash
   # Verificar instalación
   flutter doctor
   ```

2. **Android Studio** o **VS Code** con extensiones de Flutter

3. **JDK** (Java Development Kit) versión 17 o superior

### Paso 1: Clonar o Crear el Proyecto

```bash
# Navegar al directorio del proyecto
cd gestion_fabrica
```

### Paso 2: Instalar Dependencias

```bash
flutter pub get
```

### Paso 3: Generar Código (Build Runner)

Este proyecto usa generación de código para:
- Freezed (modelos inmutables)
- Drift (base de datos)
- Riverpod (providers)

```bash
# Generar código
flutter pub run build_runner build --delete-conflicting-outputs

# O en modo watch para desarrollo
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Paso 4: Compilar APK

#### APK de Depuración
```bash
flutter build apk --debug
```

#### APK de Lanzamiento (Release)
```bash
flutter build apk --release
```

El APK se generará en:
```
build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (para Google Play)
```bash
flutter build appbundle --release
```

### Paso 5: Instalar en Dispositivo

```bash
# Instalar directamente en dispositivo conectado
flutter install

# O instalar el APK manualmente
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Guía para Subir a GitHub

### Paso 1: Inicializar Repositorio Git

```bash
# Dentro del directorio del proyecto
cd gestion_fabrica

# Inicializar repositorio git
git init
```

### Paso 2: Crear Archivo .gitignore

Crear archivo `.gitignore` en la raíz del proyecto:

```gitignore
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
*.g.dart
*.freezed.dart

# Android
android/.gradle/
android/app/debug/
android/app/profile/
android/app/release/
android/key.properties
*.jks
*.keystore

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec

# IDE
.idea/
.vscode/
*.iml
*.ipr
*.iws

# Sistema operativo
.DS_Store
Thumbs.db

# Logs
*.log
```

### Paso 3: Configurar Git

```bash
# Configurar nombre y email (si no lo has hecho)
git config --global user.name "Tu Nombre"
git config --global user.email "tu@email.com"
```

### Paso 4: Crear Repositorio en GitHub

1. Ve a [GitHub](https://github.com)
2. Inicia sesión con tu cuenta
3. Haz clic en el botón **"+"** (New repository)
4. Completa la información:
   - **Repository name**: `gestion-fabrica` (o el nombre que prefieras)
   - **Description**: "Aplicación móvil para gestión de fábrica con Flutter"
   - **Visibility**: Público o Privado (según prefieras)
   - **NO** inicialices con README (ya tenemos uno)
5. Haz clic en **"Create repository"**

### Paso 5: Conectar y Subir el Código

GitHub te mostrará instrucciones. Usa estas:

```bash
# Agregar el repositorio remoto
# Reemplaza TU_USUARIO con tu nombre de usuario de GitHub
git remote add origin https://github.com/TU_USUARIO/gestion-fabrica.git

# Agregar todos los archivos
git add .

# Crear primer commit
git commit -m "Initial commit: Aplicación de gestión de fábrica completa

- Sistema de roles (Dueño/Vendedor)
- Dashboard con métricas contables
- Gestión de productos y stock
- Módulo de ventas con descuentos
- Registro de producción
- Gestión de gastos (fábrica/personales)
- Exportación a PDF
- Base de datos SQLite local
- Tema oscuro con acentos verdes"

# Subir a GitHub
git branch -M main
git push -u origin main
```

### Paso 6: Verificar en GitHub

1. Refresca la página de tu repositorio en GitHub
2. Deberías ver todos los archivos del proyecto
3. El README.md se mostrará automáticamente

## Comandos Útiles para Desarrollo

```bash
# Ejecutar en modo debug
flutter run

# Ejecutar con hot reload activo
flutter run --hot

# Ver dispositivos disponibles
flutter devices

# Limpiar build
flutter clean

# Analizar código
flutter analyze

# Formatear código
flutter format .

# Ejecutar tests
flutter test
```

## Dependencias Principales

| Paquete | Versión | Uso |
|---------|---------|-----|
| flutter_riverpod | ^2.4.9 | Gestión de estado |
| drift | ^2.14.0 | Base de datos SQLite |
| pdf | ^3.10.7 | Generación de PDFs |
| printing | ^5.11.1 | Impresión y share |
| google_fonts | ^6.1.0 | Fuentes tipográficas |
| flutter_slidable | ^3.0.1 | Acciones deslizables |
| fl_chart | ^0.66.0 | Gráficos |
| intl | ^0.18.1 | Internacionalización |
| freezed | ^2.4.5 | Modelos inmutables |
| uuid | ^4.2.1 | Generación de IDs |

## Solución de Problemas

### Error: "Generated files not found"
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "Gradle sync failed"
```bash
cd android
./gradlew clean
./gradlew build
cd ..
flutter clean
flutter pub get
```

### Error: "Kotlin version mismatch"
Actualizar `android/build.gradle`:
```gradle
ext.kotlin_version = '1.9.0'
```

### Error: "minSdkVersion too low"
Actualizar `android/app/build.gradle`:
```gradle
minSdkVersion 21
```

## Licencia

Este proyecto es de código abierto. Puedes usarlo, modificarlo y distribuirlo libremente.

## Soporte

Para preguntas o problemas, crea un issue en el repositorio de GitHub.

---

**Desarrollado con Flutter** 💙
