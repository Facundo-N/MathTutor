import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

// ─── Aurora Painter ── draws animated blurred orbs directly on canvas ───────
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

// ─── Main Screen ─────────────────────────────────────────────────────────────
class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({super.key});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _activeTab = 'home';
  bool _isDarkMode = true;
  late AnimationController _auroraCtrl;
  final TextEditingController _equationController = TextEditingController();

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
      'title': "├ülgebra B├ísica",
      'status': "5 ejercicios pendientes",
      'icon': Icons.calculate_outlined,
      'darkBg': const Color(0x3306B6D4),
      'darkIconColor': const Color(0xFF67E8F9),
      'lightBg': const Color(0xFFCFFAFE),
      'lightIconColor': const Color(0xFF0891B2),
      'darkStatus': const Color(0xFFFB7185),
      'lightStatus': const Color(0xFFF43F5E),
      'topic': '2x+4=10',
      'type': 'direct',
    },
    {
      'id': 2,
      'title': "Ecuaciones Lineales",
      'status': "3 ejercicios completados",
      'icon': Icons.show_chart_rounded,
      'darkBg': const Color(0x3310B981),
      'darkIconColor': const Color(0xFF6EE7B7),
      'lightBg': const Color(0xFFD1FAE5),
      'lightIconColor': const Color(0xFF059669),
      'darkStatus': const Color(0xFF34D399),
      'lightStatus': const Color(0xFF10B981),
      'topic': '3x-6=12',
      'type': 'direct',
    },
    {
      'id': 3,
      'title': "Factorización",
      'status': "2 ejercicios nuevos",
      'icon': Icons.hub_rounded,
      'darkBg': const Color(0x33A855F7),
      'darkIconColor': const Color(0xFFD8B4FE),
      'lightBg': const Color(0xFFF3E8FF),
      'lightIconColor': const Color(0xFF9333EA),
      'darkStatus': const Color(0xFF22D3EE),
      'lightStatus': const Color(0xFF3B82F6),
      'topic': 'x²-25=0',
      'type': 'direct',
    },
    {
      'id': 4,
      'title': "Geometría",
      'status': "1 ejercicio pendiente",
      'icon': Icons.change_history_rounded,
      'darkBg': const Color(0x33D946EF),
      'darkIconColor': const Color(0xFFF0ABFC),
      'lightBg': const Color(0xFFFAEAFF),
      'lightIconColor': const Color(0xFFC026D3),
      'darkStatus': const Color(0xFFFB7185),
      'lightStatus': const Color(0xFFF43F5E),
      'topic': 'x=10',
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
    final bgColor = _isDarkMode
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
                color: _isDarkMode ? const Color(0xFF0A0F1E) : Colors.white,
                child: Stack(
                  children: [
                    // ── Animated Aurora ────────────────────────────────────
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AuroraPainter(
                          t: _auroraCtrl.value,
                          isDarkMode: _isDarkMode,
                        ),
                      ),
                    ),

                    // ── Content ────────────────────────────────────────────
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
                                        child: ScaleTransition(
                                          scale: Tween(
                                            begin: 0.96,
                                            end: 1.0,
                                          ).animate(anim),
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

  // ─── Tab switcher ──────────────────────────────────────────────────────────
  Widget _buildCurrentTab() {
    switch (_activeTab) {
      case 'home':
        return _buildHomeTab();
      case 'stats':
        return _buildStatsTab();
      case 'chat':
      case 'profile':
        return SizedBox(
          key: ValueKey(_activeTab),
          height: 256,
          child: Center(
            child: Text(
              'Contenido de $_activeTab próximamente',
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

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _glassBtn(
              child: Icon(
                _isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                color: _isDarkMode
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFF6366F1),
                size: 22,
              ),
              onTap: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
            const SizedBox(width: 8),
            _glassBtn(
              child: Icon(
                Icons.search,
                color: _isDarkMode ? Colors.white : const Color(0xFF475569),
                size: 22,
              ),
            ),
          ],
        ),
        // Streak badge
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: _isDarkMode
                    ? const Color(0x22F43F5E)
                    : const Color(0xFFFFF1F2),
                border: Border.all(
                  color: _isDarkMode
                      ? const Color(0x44F43F5E)
                      : const Color(0xFFFFE4E6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: _isDarkMode
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
                      color: _isDarkMode
                          ? const Color(0xFFFDA4AF)
                          : const Color(0xFFE11D48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassBtn({required Widget child, VoidCallback? onTap}) {
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
              color: _isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: _isDarkMode
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

  // ─── Home Tab ──────────────────────────────────────────────────────────────
  Widget _buildHomeTab() {
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
                  color: _isDarkMode
                      ? Colors.white.withValues(alpha: 0.10)
                      : const Color(0xFFECFEFF),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFFCFFAFE),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.school_outlined,
                    size: 38,
                    color: _isDarkMode
                        ? const Color(0xFF67E8F9)
                        : const Color(0xFF06B6D4),
                  ),
                ),
              ),
              Text(
                '¡Listo para aprender!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Continúa tu racha diaria',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode
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
                color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDarkMode
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

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: classes.length,
          itemBuilder: (_, i) {
            final cls = classes[i];
            return GestureDetector(
              onTap: () {
                if (cls['type'] == 'learning_flow') {
                  Navigator.pushNamed(
                    context,
                    '/learning-flow',
                    arguments: {'topicId': cls['topic']},
                  );
                } else {
                  // Navegación directa para temas previos que el usuario prefiere
                  Navigator.pushNamed(
                    context,
                    '/board',
                    arguments: cls['topic'],
                  );
                }
              },
              child: _glassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: _isDarkMode ? cls['darkBg'] : cls['lightBg'],
                          ),
                          child: Icon(
                            cls['icon'] as IconData,
                            size: 24,
                            color: _isDarkMode
                                ? cls['darkIconColor']
                                : cls['lightIconColor'],
                          ),
                        ),
                        Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: _isDarkMode
                              ? const Color(0xFF64748B)
                              : const Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      cls['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        height: 1.2,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      (cls['status'] as String).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: _isDarkMode
                            ? cls['darkStatus'] as Color
                            : cls['lightStatus'] as Color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Stats Tab ─────────────────────────────────────────────────────────────
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
                        'Histórico anual',
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
                          'Último año',
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
              // ── Bar chart using LayoutBuilder to avoid height errors ──────
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
                      '7 días',
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

  // ─── Bottom Nav ────────────────────────────────────────────────────────────
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
              _navItem('stats', Icons.insights_rounded), // Estadísticas
              _navItem('profile', Icons.school_rounded), // Perfil/logros
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

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Widget _glassCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? extraColor,
    Color? borderColor,
  }) {
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
                (_isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.75)),
            border: Border.all(
              color:
                  borderColor ??
                  (_isDarkMode
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0)),
            ),
            boxShadow: _isDarkMode
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

  Widget _dot({bool wide = false}) => Container(
    width: wide ? 28 : 6,
    height: 6,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      color: wide
          ? (_isDarkMode ? const Color(0xFF22D3EE) : const Color(0xFF06B6D4))
          : (_isDarkMode
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFFCBD5E1)),
      boxShadow: wide && _isDarkMode
          ? [const BoxShadow(color: Color(0x9922D3EE), blurRadius: 8)]
          : [],
    ),
  );

  // ─── Modal Selection ────────────────────────────────────────────────────────
}

// ─── Line Chart Painter ────────────────────────────────────────────────────
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
