#!/bin/bash

# Script de compilación para Gestión Fábrica
# Uso: ./build_apk.sh [debug|release]

set -e

MODE="${1:-release}"

echo "=========================================="
echo "  Gestión Fábrica - Compilación APK"
echo "  Modo: $MODE"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar Flutter
print_status "Verificando Flutter..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter no está instalado o no está en el PATH"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
print_success "Flutter encontrado: $FLUTTER_VERSION"

# Limpiar build anterior
print_status "Limpiando builds anteriores..."
flutter clean
print_success "Build limpiado"

# Obtener dependencias
print_status "Instalando dependencias..."
flutter pub get
print_success "Dependencias instaladas"

# Generar código (si es necesario)
print_status "Verificando archivos generados..."
if [ ! -f "lib/services/database.g.dart" ]; then
    print_warning "Archivos generados no encontrados. Ejecutando build_runner..."
    flutter pub run build_runner build --delete-conflicting-outputs
    print_success "Código generado"
else
    print_success "Archivos generados encontrados"
fi

# Analizar código
print_status "Analizando código..."
flutter analyze
print_success "Análisis completado"

# Compilar APK
print_status "Compilando APK en modo $MODE..."
echo ""

if [ "$MODE" = "debug" ]; then
    flutter build apk --debug
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
else
    flutter build apk --release
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
fi

print_success "APK compilado exitosamente!"
echo ""

# Verificar que el APK existe
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    print_success "APG generado: $APK_PATH"
    print_success "Tamaño: $APK_SIZE"
    echo ""
    
    # Mostrar información del APK
    print_status "Información del APK:"
    echo "  - Ubicación: $APK_PATH"
    echo "  - Tamaño: $APK_SIZE"
    echo "  - Modo: $MODE"
    echo ""
    
    # Preguntar si desea instalar
    if [ "$MODE" = "debug" ]; then
        read -p "¿Deseas instalar el APK en el dispositivo conectado? (s/n): " INSTALL
        if [ "$INSTALL" = "s" ] || [ "$INSTALL" = "S" ]; then
            print_status "Instalando APK..."
            flutter install
            print_success "APK instalado"
        fi
    fi
else
    print_error "No se encontró el APK en la ruta esperada"
    exit 1
fi

echo ""
echo "=========================================="
echo "  Compilación completada exitosamente!"
echo "=========================================="
