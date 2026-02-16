#!/bin/bash

echo "🧹 Limpiando archivos obsoletos de MathTutor..."

# Screens obsoletos
rm -f lib/screens/unified_session_screen.dart
rm -f lib/screens/session_screen.dart
rm -f lib/screens/tutor_screen.dart

# Widgets obsoletos
rm -f lib/widgets/orientation_controller.dart
rm -f lib/widgets/landscape_board.dart
rm -f lib/widgets/portrait_avatar.dart
rm -f lib/widgets/orientation_transition.dart

# Services obsoletos
rm -f lib/services/orientation_service.dart
rm -f lib/services/screen_mode_manager.dart

# Providers obsoletos
rm -f lib/providers/orientation_provider.dart
rm -f lib/providers/screen_mode_provider.dart

echo "✅ Limpieza completada!"
echo ""
echo "📋 Archivos mantenidos:"
echo "  - lib/screens/new_home_screen.dart"
echo "  - lib/screens/banny_chat_screen.dart"
echo "  - lib/screens/presentation_slide.dart"
echo "  - lib/screens/style_onboarding_screen.dart"
echo ""
echo "🔍 Ejecutá 'flutter pub get' para verificar dependencias"
