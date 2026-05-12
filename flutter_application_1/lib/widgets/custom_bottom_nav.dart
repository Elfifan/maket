import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _primaryPurple = Color(0xFFA58EFF);
  static const Color _accentPink = Color(0xFFF2C9D4);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    final items = [
      _NavItem(Icons.grid_view_rounded, Icons.grid_view_outlined, 'Каталог'),
      _NavItem(Icons.book_rounded, Icons.book_outlined, 'Чаты'),
      _NavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'ИИ'),
      _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Профиль'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.04) 
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isSelected = currentIndex == index;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onTap(index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 16 : 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? _primaryPurple.withValues(alpha: isDark ? 0.2 : 0.1) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected && isDark
                          ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? items[index].activeIcon : items[index].icon,
                          color: isSelected ? _primaryPurple : (isDark ? Colors.white54 : const Color(0xFF9094A6)),
                          size: 24,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: isSelected
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    items[index].label,
                                    style: TextStyle(
                                      color: isSelected ? _primaryPurple : (isDark ? Colors.white54 : const Color(0xFF9094A6)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;

  _NavItem(this.activeIcon, this.icon, this.label);
}