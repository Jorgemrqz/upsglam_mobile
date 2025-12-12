@echo off
echo ==========================================
echo       UPSGlam - Generador de Iconos
echo ==========================================
echo.
echo Deteniendo procesos de Dart/Flutter que puedan bloquear archivos...
taskkill /F /IM dart.exe >nul 2>&1

echo.
echo Limpiando caché antigua (necesario para ver cambios de icono)...
call flutter clean

echo.
echo Obteniendo dependencias...
call flutter pub get

echo.
echo Generando iconos de la app...
call dart run flutter_launcher_icons

echo.
echo ==========================================
echo LISTO! Los iconos se han actualizado.
echo Ahora ejecuta 'flutter run' o reinicia la app para verlos.
echo ==========================================
pause
