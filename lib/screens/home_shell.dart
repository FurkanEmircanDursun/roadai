import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/drive_controller.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'music_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

/// Alt gezinmeli ana kabuk.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    ReportsScreen(),
    MusicScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final driving =
        context.select<DriveController, bool>((d) => d.state == DriveState.running);

    return Scaffold(
      extendBody: true,
      // Sekme degisiminde ekran yeniden kurulur; raporlar boylece hep guncel.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _screens[_index],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: AppTheme.cardBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.directions_car_rounded,
                  label: 'Sürüş',
                  selected: _index == 0,
                  badge: driving,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.insert_chart_rounded,
                  label: 'Raporlar',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: Icons.library_music_rounded,
                  label: 'Müzik',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Ayarlar',
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accent : AppTheme.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (badge)
                    Positioned(
                      right: -3,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3DDC84),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
