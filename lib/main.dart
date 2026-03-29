// lib/main.dart (VERSIÓN LIMPIA - SOLO NUEVA INTERFAZ)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Screens - Solo nueva interfaz
import 'screens/presentation_slide.dart';
import 'screens/style_onboarding_screen.dart';
import 'screens/modern_dashboard_screen.dart';
import 'screens/banny_chat_screen.dart';
import 'screens/unified_board_chat_screen.dart';

// Providers
import 'services/visual_style_provider.dart';
import 'providers/adaptive_style_provider.dart';
import 'providers/board_provider.dart';
import 'providers/user_provider.dart';
import 'package:demo_33_v2/screens/learning_flow_screen.dart';
import 'screens/onboarding_survey_screen.dart';
import 'screens/destructor_preview_screen.dart';

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
        ChangeNotifierProvider(create: (_) => UserProvider()..initUser()),
      ],
      child: MaterialApp(
        title: 'MathTutor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5CE7)),
          fontFamily: 'Poppins',
        ),

        // ✅ Ruta inicial: Presentación de slides
        initialRoute: '/',

        // ✅ Rutas estáticas
        routes: {
          '/': (context) => const PresentationScreen(),
          '/style-onboarding': (context) => const StyleOnboardingScreen(),
          '/onboarding-survey': (context) => const OnboardingSurveyScreen(),
          '/home': (context) => const ModernDashboardScreen(),
          '/chat': (context) => BannyChatScreen(
            userId: context.read<UserProvider>().userId ?? 'user_anonymous',
          ),
          '/equation_lab': (context) =>
              const UnifiedBoardChatScreen(equation: ''),
        },

        // ✅ Rutas con parámetros dinámicos
        onGenerateRoute: (settings) {
          if (settings.name == '/board') {
            String equation = '';
            String template = 'guiado';

            if (settings.arguments is String) {
              equation = settings.arguments as String;
            } else if (settings.arguments is Map) {
              final args = settings.arguments as Map;
              equation = args['equation'] as String? ?? '';
              template = args['template'] as String? ?? 'guiado';
            }

            return MaterialPageRoute(
              builder: (context) => UnifiedBoardChatScreen(
                equation: equation,
                template: template,
              ),
            );
          } else if (settings.name == '/destructor-preview') {
            String topicId = 'all';
            if (settings.arguments is String) {
              topicId = settings.arguments as String;
            } else if (settings.arguments is Map) {
              topicId =
                  (settings.arguments as Map)['topicId'] as String? ?? 'all';
            }
            return MaterialPageRoute(
              builder: (context) => DestructorPreviewScreen(topicId: topicId),
            );
          } else if (settings.name == '/learning-flow') {
            String topicId = 'linear';
            String? initialEquation;
            if (settings.arguments is Map) {
              final args = settings.arguments as Map;
              topicId = args['topicId'] as String? ?? 'linear';
              initialEquation = args['initialEquation'] as String?;
            }
            return MaterialPageRoute(
              builder: (context) => LearningFlowScreen(
                topicId: topicId,
                initialEquation: initialEquation,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
