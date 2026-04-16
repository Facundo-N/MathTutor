// lib/main.dart (VERSIÓN LIMPIA - SOLO NUEVA INTERFAZ)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Screens - Solo nueva interfaz
import 'screens/presentation_slide.dart';
import 'screens/modern_dashboard_screen.dart';
import 'screens/banny_chat_screen.dart';
import 'screens/unified_board_chat_screen.dart';
import 'screens/learning_flow_screen.dart';

// Providers
import 'providers/theme_provider.dart';
import 'services/visual_style_provider.dart';
import 'providers/adaptive_style_provider.dart';
import 'providers/board_provider.dart';
import 'providers/user_provider.dart';
import 'screens/onboarding_survey_screen.dart';
import 'screens/destructor_preview_screen.dart';
import 'screens/profile_screen.dart';

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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: PremiumPageTransitionsBuilder(),
              TargetPlatform.iOS: PremiumPageTransitionsBuilder(),
              TargetPlatform.windows: PremiumPageTransitionsBuilder(),
              TargetPlatform.linux: PremiumPageTransitionsBuilder(),
              TargetPlatform.macOS: PremiumPageTransitionsBuilder(),
            },
          ),
        ),

        // ✅ Ruta inicial: Presentación de slides
        initialRoute: '/',

        // ✅ Rutas estáticas
        routes: {
          '/': (context) => const PresentationScreen(),
          '/onboarding-survey': (context) => const OnboardingSurveyScreen(),
          '/home': (context) => const ModernDashboardScreen(),
          '/chat': (context) => BannyChatScreen(
            userId: context.read<UserProvider>().userId ?? 'user_anonymous',
          ),
          '/equation_lab': (context) =>
              const UnifiedBoardChatScreen(equation: ''),
          '/profile': (context) => const ProfileScreen(),
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

class PremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const PremiumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: const Offset(0.0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
            ),
        child: child,
      ),
    );
  }
}
