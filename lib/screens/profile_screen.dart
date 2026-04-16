import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF020617) : const Color(0xFFF1F5F9);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background blurred elements
          Positioned(
            top: -100,
            right: -100,
            child: _blurOrb(isDark ? const Color(0x332563EB) : const Color(0x223B82F6), 300),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _blurOrb(isDark ? const Color(0x22A855F7) : const Color(0x119333EA), 250),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, textColor),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildUserAvatar(userProvider, isDark),
                        const SizedBox(height: 32),
                        _buildSettingsGroup(
                          'Apariencia',
                          [
                            _buildSettingTile(
                              icon: isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                              title: 'Modo Oscuro',
                              subtitle: isDark ? 'Activado' : 'Desactivado',
                              trailing: Switch(
                                value: isDark,
                                activeColor: const Color(0xFF3B82F6),
                                onChanged: (val) => themeProvider.toggleTheme(),
                              ),
                              isDark: isDark,
                            ),
                          ],
                          isDark,
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsGroup(
                          'Preferencias de Aprendizaje',
                          [
                            _buildSettingTile(
                              icon: Icons.psychology_outlined,
                              title: 'Nivel de ayuda',
                              subtitle: userProvider.profile?.scaffoldingLevel ?? 'Moderado',
                              isDark: isDark,
                            ),
                            _buildSettingTile(
                              icon: Icons.record_voice_over_outlined,
                              title: 'Tono del Tutor',
                              subtitle: userProvider.profile?.preferredTone ?? 'Motivador',
                              isDark: isDark,
                            ),
                          ],
                          isDark,
                        ),
                        const SizedBox(height: 40),
                        _buildLogoutButton(isDark),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: textColor.withOpacity(0.05),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Mi Perfil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(UserProvider userProvider, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Estudiante', // Placeholder o nombre de userProvider
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${userProvider.userId?.substring(0, 8) ?? "..."}',
          style: TextStyle(
            fontSize: 14,
            color: textColor.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children, bool isDark) {
    final titleColor = isDark ? Colors.white70 : Colors.black87;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: titleColor.withOpacity(0.5),
            ),
          ),
        ),
        _glassContainer(
          padding: EdgeInsets.zero,
          isDark: isDark,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: textColor.withOpacity(0.05),
                ),
                child: Icon(icon, size: 20, color: textColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark 
            ? [Colors.redAccent.withOpacity(0.3), Colors.transparent]
            : [Colors.red.withOpacity(0.1), Colors.transparent],
        ),
      ),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({required Widget child, required EdgeInsets padding, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _blurOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
