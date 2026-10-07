import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum NavTab { home, chatbot, scan, history, settings }

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.current,
    required this.onHomeTap,
    required this.onChatbotTap,
    required this.onFrameTap,
    required this.onHistoryTap,
    required this.onSettingsTap,
  });

  final NavTab current;
  final VoidCallback onHomeTap;
  final VoidCallback onChatbotTap;
  final VoidCallback onFrameTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 3),
          child: SizedBox(
            height: 60,
            child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  isSelected: current == NavTab.home,
                  onTap: onHomeTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.forum,
                  label: 'Chatbot',
                  isSelected: current == NavTab.chatbot,
                  onTap: onChatbotTap,
                ),
              ),
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: onFrameTap,
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/scan_button.png',
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.history,
                  label: 'History',
                  isSelected: current == NavTab.history,
                  onTap: onHistoryTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: current == NavTab.settings,
                  onTap: onSettingsTap,
                ),
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
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.forest : AppColors.navInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 27, color: color),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
