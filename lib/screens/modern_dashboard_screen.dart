import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';

// â”€â”€â”€ Aurora Painter â”€â”€ draws animated blurred orbs directly on canvas â”€â”€â”€â”€â”€â”€â”€
class _AuroraPainter extends CustomPainter {
  final double t; // Animation tick 0..1 looping
  final bool isDarkMode;

  _AuroraPainter({required this.t, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    // Three orbs that move in slow lissajous-like paths
    final orbs = [
      _OrbConfig(
        baseX: 0.1,
        baseY: 0.05,
        ampX: 0.25,
        ampY: 0.18,
        freqX: 1.0,
        freqY: 0.7,
        radius: size.shortestSide * 0.65,
        darkColor: const Color(0x5E2563EB), // blue-600
        lightColor: const Color(0x7793C5FD), // blue-300
      ),
      _OrbConfig(
        baseX: 0.85,
        baseY: 0.55,
        ampX: 0.22,
        ampY: 0.20,
        freqX: 0.6,
        freqY: 1.1,
        radius: size.shortestSide * 0.55,
        darkColor: const Color(0x440EA5E9), // sky-500
        lightColor: const Color(0x6638BDF8), // sky-400
      ),
      _OrbConfig(
        baseX: 0.15,
        baseY: 0.88,
        ampX: 0.20,
        ampY: 0.15,
        freqX: 0.8,
        freqY: 0.5,
        radius: size.shortestSide * 0.70,
        darkColor: const Color(0x333B82F6), // blue-500
        lightColor: const Color(0x5560A5FA), // blue-400
      ),
    ];

    for (final orb in orbs) {
      final cx =
          size.width *
          (orb.baseX + orb.ampX * math.sin(2 * math.pi * t * orb.freqX));
      final cy =
          size.height *
          (orb.baseY + orb.ampY * math.cos(2 * math.pi * t * orb.freqY));
      final color = isDarkMode ? orb.darkColor : orb.lightColor;

      final paint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80)
        ..color = color;
      canvas.drawCircle(Offset(cx, cy), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.isDarkMode != isDarkMode;
}

class _OrbConfig {
  final double baseX, baseY, ampX, ampY, freqX, freqY, radius;
  final Color darkColor, lightColor;
  const _OrbConfig({
    required this.baseX,
    required this.baseY,
    required this.ampX,
    required this.ampY,
    required this.freqX,
    required this.freqY,
    required this.radius,
    required this.darkColor,
    required this.lightColor,
  });
}

// â”€â”€â”€ Main Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({super.key});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _activeTab = 'home';
  late AnimationController _auroraCtrl;
  final TextEditingController _equationController = TextEditingController();

  bool get _isDarkMode => Provider.of<ThemeProvider>(context).isDarkMode;

  final List<double> barChartData = [
    30,
    45,
    55,
    60,
    20,
    10,
    80,
    45,
    65,
    20,
    30,
  ];
  final List<String> barChartLabels = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
  ];

  final List<Map<String, dynamic>> classes = [
    {
      'id': 1,
      'title': "Crear Proyecto",
      'status': "Personalizado",
      'icon': Icons.add_circle_outline_rounded,
      'darkBg': const Color(0x3306B6D4),
      'darkIconColor': const Color(0xFF67E8F9),
      'lightBg': const Color(0xFFCFFAFE),
      'lightIconColor': const Color(0xFF0891B2),
      'darkStatus': const Color(0xFFFB7185),
      'lightStatus': const Color(0xFFF43F5E),
      'topic': '',
      'type': 'direct',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Very slow 25-second loop for a calm water-like aurora
    _auroraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _auroraCtrl.dispose();
    _equationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    final bgColor = isDarkMode
        ? const Color(0xFF020617)
        : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _auroraCtrl,
        builder: (ctx, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                color: isDarkMode ? const Color(0xFF0A0F1E) : Colors.white,
                child: Stack(
                  children: [
                    // â”€â”€ Animated Aurora â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AuroraPainter(
                          t: _auroraCtrl.value,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ),

                    // â”€â”€ Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                    SafeArea(
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: 24,
                              bottom: 120,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 32),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.0, 0.025),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: anim,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: child,
                                        ),
                                      ),
                                  child: _buildCurrentTab(),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 20,
                            right: 20,
                            child: _buildBottomNav(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // â”€â”€â”€ Tab switcher â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildCurrentTab() {
    switch (_activeTab) {
      case 'home':
        return _buildHomeTab();
      case 'stats':
        return _buildStatsTab();
      case 'chat':
        return SizedBox(
          key: ValueKey(_activeTab),
          height: 256,
          child: Center(
            child: Text(
              'Contenido de $_activeTab prÃ³ximamente',
              style: TextStyle(
                color: _isDarkMode
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  // â”€â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _glassBtn(
              child: Icon(
                isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                color: isDarkMode
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFF6366F1),
                size: 22,
              ),
              onTap: () => context.read<ThemeProvider>().toggleTheme(),
            ),
            const SizedBox(width: 8),
            _glassBtn(
              child: Icon(
                Icons.search,
                color: isDarkMode ? Colors.white : const Color(0xFF475569),
                size: 22,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Streak badge
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: isDarkMode
                        ? const Color(0x22F43F5E)
                        : const Color(0xFFFFF1F2),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0x44F43F5E)
                          : const Color(0xFFFFE4E6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: isDarkMode
                            ? const Color(0xFFFB7185)
                            : const Color(0xFFF43F5E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '5',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDarkMode
                              ? const Color(0xFFFDA4AF)
                              : const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Profile entry
            _glassBtn(
              child: Icon(
                Icons.person_outline_rounded,
                color: isDarkMode ? Colors.white : const Color(0xFF475569),
                size: 22,
              ),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _glassBtn({required Widget child, VoidCallback? onTap}) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Home Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHomeTab() {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return Column(
      key: const ValueKey('home'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Banner
        _glassCard(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Icon circle
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.10)
                      : const Color(0xFFECFEFF),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFFCFFAFE),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.school_outlined,
                    size: 38,
                    color: isDarkMode
                        ? const Color(0xFF67E8F9)
                        : const Color(0xFF06B6D4),
                  ),
                ),
              ),
              Text(
                'Â¡Listo para aprender!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ContinÃºa tu racha diaria',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              // Pagination dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(wide: true),
                  const SizedBox(width: 6),
                  _dot(),
                  const SizedBox(width: 6),
                  _dot(),
                ],
              ),
            ],
          ),
        ),

        // Section title
        Row(
          children: [
            Text(
              'Mis clases',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.transparent,
                          ]
                        : [const Color(0xFFE2E8F0), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        const SizedBox(height: 20),
        _buildProjectTemplateGrid(),
      ],
    );
  }

  Widget _buildProjectTemplateGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        return TemplateCardWidget(
          isDarkMode: _isDarkMode,
          classInfo: classes[index],
        );
      },
    );
  }

  // â”€â”€â”€ Stats Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildStatsTab() {
    return Column(
      key: const ValueKey('stats'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi rendimiento',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),

        // Segmented control
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _isDarkMode
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFFF1F5F9),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _isDarkMode
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: _isDarkMode ? 0.2 : 0.06,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Tema',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isDarkMode
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Mi nivel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _isDarkMode
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Bar Chart
        _glassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ejercicios aprobados',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: _isDarkMode
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'HistÃ³rico anual',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDarkMode
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF8FAFC),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Ãšltimo aÃ±o',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isDarkMode
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: _isDarkMode
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // â”€â”€ Bar chart using LayoutBuilder to avoid height errors â”€â”€â”€â”€â”€â”€
              SizedBox(
                height: 150,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final chartH = constraints.maxHeight;
                    // Reserve 24px bottom for labels, rest is bars
                    const labelH = 22.0;
                    final barAreaH = chartH - labelH;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(barChartData.length, (i) {
                        final isHi = i == 6;
                        final frac = barChartData[i] / 100.0;
                        final barH = (barAreaH * frac).clamp(4.0, barAreaH);

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  height: barH,
                                  decoration: BoxDecoration(
                                    color: isHi
                                        ? (_isDarkMode
                                              ? const Color(0xFF60A5FA)
                                              : const Color(0xFF3B82F6))
                                        : (_isDarkMode
                                              ? Colors.white.withValues(
                                                  alpha: 0.12,
                                                )
                                              : const Color(0xFFE2E8F0)),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                    boxShadow: isHi && _isDarkMode
                                        ? [
                                            const BoxShadow(
                                              color: Color(0x663B82F6),
                                              blurRadius: 14,
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  barChartLabels[i],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    color: isHi
                                        ? (_isDarkMode
                                              ? const Color(0xFF93C5FD)
                                              : const Color(0xFF2563EB))
                                        : (_isDarkMode
                                              ? const Color(0xFF475569)
                                              : const Color(0xFF94A3B8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Line Chart
        _glassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progreso de nivel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: _isDarkMode ? Colors.white : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: _LineChartPainter(isDarkMode: _isDarkMode),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                color: _isDarkMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final l in ['Ago 12', '19', '26', 'Sep 2'])
                    Text(
                      l,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bottom stat cards
        Row(
          children: [
            Expanded(
              child: _glassCard(
                padding: const EdgeInsets.all(20),
                extraColor: _isDarkMode
                    ? const Color(0x1AF43F5E)
                    : const Color(0xFFFFF1F2),
                borderColor: _isDarkMode
                    ? const Color(0x33F43F5E)
                    : const Color(0xFFFFE4E6),
                child: Column(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 30,
                      color: _isDarkMode
                          ? const Color(0xFFFB7185)
                          : const Color(0xFFF43F5E),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '7 dÃ­as',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RACHA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: _isDarkMode
                            ? const Color(0xB3FDA4AF)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _glassCard(
                padding: const EdgeInsets.all(20),
                extraColor: _isDarkMode
                    ? const Color(0x1A3B82F6)
                    : const Color(0xFFEFF6FF),
                borderColor: _isDarkMode
                    ? const Color(0x333B82F6)
                    : const Color(0xFFDBEAFE),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ACIERTOS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: _isDarkMode
                            ? const Color(0xB393C5FD)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '86%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // â”€â”€â”€ Bottom Nav â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: _isDarkMode
                ? Colors.black.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: _isDarkMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isDarkMode ? 0.5 : 0.08),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem('home', Icons.home_rounded),
              _navItem('chat', Icons.functions_rounded), // Laboratorio
              _navItem('stats', Icons.insights_rounded), // EstadÃ­sticas
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String id, IconData icon) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () {
        if (id == 'chat') {
          final userId =
              context.read<UserProvider>().userId ?? 'user_anonymous';
          Navigator.pushNamed(
            context,
            '/board',
            arguments: {'equation': '', 'userId': userId},
          );
        } else {
          setState(() => _activeTab = id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isActive
              ? [const BoxShadow(color: Color(0x663B82F6), blurRadius: 18)]
              : [],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: isActive
                ? Colors.white
                : (_isDarkMode
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _glassCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? extraColor,
    Color? borderColor,
  }) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color:
                extraColor ??
                (isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.75)),
            border: Border.all(
              color:
                  borderColor ??
                  (isDarkMode
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0)),
            ),
            boxShadow: isDarkMode
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _dot({bool wide = false}) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return Container(
      width: wide ? 28 : 6,
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: wide
            ? (isDarkMode ? const Color(0xFF22D3EE) : const Color(0xFF06B6D4))
            : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFCBD5E1)),
        boxShadow: wide && isDarkMode
            ? [const BoxShadow(color: Color(0x9922D3EE), blurRadius: 8)]
            : [],
      ),
    );
  }

  // â”€â”€â”€ Modal Selection â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
}

// â”€â”€â”€ Line Chart Painter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LineChartPainter extends CustomPainter {
  final bool isDarkMode;
  _LineChartPainter({required this.isDarkMode});

  static const _pts = [
    Offset(0, 20),
    Offset(10, 25),
    Offset(20, 18),
    Offset(30, 30),
    Offset(40, 15),
    Offset(50, 12),
    Offset(60, 20),
    Offset(70, 5),
    Offset(75, 25),
    Offset(85, 15),
    Offset(95, 25),
    Offset(100, 20),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 40;

    // Grid lines
    final gridPaint = Paint()
      ..color = isDarkMode
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF1F5F9)
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        gridPaint,
      );
    }

    final path = Path();
    final area = Path();
    for (var i = 0; i < _pts.length; i++) {
      final x = _pts[i].dx * sx;
      final y = _pts[i].dy * sy;
      if (i == 0) {
        path.moveTo(x, y);
        area.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        area.lineTo(x, y);
      }
    }
    area
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Gradient fill
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: isDarkMode ? 0.28 : 0.12),
            const Color(0xFF3B82F6).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Glow
    if (isDarkMode) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF3B82F6)
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Data points
    for (final idx in [2, 3, 5, 7, 8, 10]) {
      final x = _pts[idx].dx * sx;
      final y = _pts[idx].dy * sy;
      if (isDarkMode) {
        canvas.drawCircle(
          Offset(x, y),
          3.5,
          Paint()
            ..color = const Color(0xFF3B82F6).withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()
          ..color = const Color(0xFF3B82F6)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.isDarkMode != isDarkMode;
}

// â”€â”€â”€ TemplateCardWidget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class TemplateCardWidget extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic> classInfo;

  const TemplateCardWidget({
    super.key,
    required this.isDarkMode,
    required this.classInfo,
  });

  @override
  State<TemplateCardWidget> createState() => _TemplateCardWidgetState();
}

class _TemplateCardWidgetState extends State<TemplateCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _showCreateProjectDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = widget.isDarkMode;
        final icon = widget.classInfo['icon'];
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: isDark ? Colors.white : const Color(0xFF2563EB)),
              ),
              const SizedBox(height: 16),
              Text(
                'Nuevo Proyecto',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Â¿CÃ³mo se llamarÃ¡ tu proyecto?',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Nombre del proyecto',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  filled: true,
                  fillColor: isDark 
                    ? const Color(0xFF0F172A) 
                    : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF94A3B8), fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final projectName = nameController.text.trim();
                if (projectName.isEmpty) return;

                Navigator.pop(ctx);
                final userId = context.read<UserProvider>().userId ?? 'user_anonymous';
                Navigator.pushNamed(
                  context,
                  '/board',
                  arguments: {'equation': '', 'userId': userId, 'projectName': projectName},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Iniciar',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return GestureDetector(
      onTapDown: (_) => _animCtrl.forward(),
      onTapUp: (_) {
        _animCtrl.reverse();
        _showCreateProjectDialog();
      },
      onTapCancel: () => _animCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              if (!isDarkMode)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              // Mock Graphic area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Illustration Shapes
                      Center(
                        child: Opacity(
                          opacity: 0.3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.change_history, 
                                size: 44, 
                                color: isDarkMode ? Colors.white : const Color(0xFF94A3B8)
                              ),
                              Transform.translate(
                                offset: const Offset(-8, 0),
                                child: Icon(
                                  Icons.circle, 
                                  size: 40, 
                                  color: isDarkMode ? Colors.white : const Color(0xFFCBD5E1)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Floating top-right button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode ? Colors.black.withValues(alpha: 0.3) : Colors.white,
                            border: Border.all(
                              color: isDarkMode ? Colors.white24 : Colors.black12,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: isDarkMode ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Skeleton Lines
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      width: 60,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

