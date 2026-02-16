// lib/main.dart (VERSIÓN LIMPIA - SOLO NUEVA INTERFAZ)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Screens - Solo nueva interfaz
import 'screens/presentation_slide.dart';
import 'screens/style_onboarding_screen.dart';
import 'screens/new_home_screen.dart';
import 'screens/banny_chat_screen.dart';
import 'screens/board_screen.dart';

// Providers
import 'services/visual_style_provider.dart';
import 'providers/adaptive_style_provider.dart';
import 'providers/board_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Forzar solo modo vertical (opcional)
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MathTutorApp());
}

class MathTutorApp extends StatelessWidget {
  const MathTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VisualStyleProvider()),
        ChangeNotifierProvider(create: (_) => AdaptiveStyleProvider()),
        ChangeNotifierProvider(create: (_) => BoardProvider()),
      ],
      child: MaterialApp(
        title: 'MathTutor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5CE7)),
          fontFamily: 'Poppins', // Opcional
        ),

        // ✅ Ruta inicial: Presentación de slides
        initialRoute: '/',

        // ✅ Rutas - Solo nueva interfaz
        routes: {
          '/': (context) => const PresentationScreen(),
          '/style-onboarding': (context) => const StyleOnboardingScreen(),
          '/home': (context) => const NewHomeScreen(),
          '/chat': (context) => const BannyChatScreen(userId: 'user_123'),
        },

        // ✅ Rutas con parámetros dinámicos
        onGenerateRoute: (settings) {
          if (settings.name == '/board') {
            // Ecuación por defecto para demo
            final equation = settings.arguments as String? ?? '2x+4=10';
            return MaterialPageRoute(
              builder: (context) => BoardScreen(equation: equation),
            );
          }
          return null;
        },
      ),
    );
  }
}
