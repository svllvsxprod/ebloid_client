import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

@immutable
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.enabled = true,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool enabled;
  final int badgeCount;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AppBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return ColoredBox(
      color: colors.bg,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.divider),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / items.length;
                  final duration = AppMotion.resolve(context, AppMotion.normal);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedPositionedDirectional(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        start: selectedIndex * itemWidth + 2,
                        top: 0,
                        bottom: 0,
                        width: itemWidth - 4,
                        child: DecoratedBox(
                          key: const Key('tab-selection-indicator'),
                          decoration: BoxDecoration(
                            color: colors.soft,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var index = 0; index < items.length; index++)
                            Expanded(
                              child: _AppBottomNavTile(
                                item: items[index],
                                selected: index == selectedIndex,
                                colors: colors,
                                textStyle: text.labelSmall,
                                duration: duration,
                                onTap: items[index].enabled
                                    ? () => onDestinationSelected(index)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBottomNavTile extends StatelessWidget {
  const _AppBottomNavTile({
    required this.item,
    required this.selected,
    required this.colors,
    required this.textStyle,
    required this.duration,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final AppColors colors;
  final TextStyle? textStyle;
  final Duration duration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? colors.accent : colors.muted;
    return Semantics(
      enabled: item.enabled,
      button: true,
      selected: selected,
      label: item.enabled
          ? item.badgeCount > 0
                ? '${item.label}. Непрочитанных: ${item.badgeCount}'
                : item.label
          : '${item.label}. Раздел пока недоступен',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: .86,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Badge.count(
                      count: item.badgeCount,
                      isLabelVisible: item.badgeCount > 0,
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        key: ValueKey(selected),
                        size: 22,
                        color: item.enabled
                            ? color
                            : colors.muted.withValues(alpha: .45),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: Curves.easeOut,
                    style:
                        textStyle?.copyWith(
                          color: item.enabled
                              ? (selected ? colors.fg : color)
                              : colors.muted.withValues(alpha: .45),
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: .2,
                        ) ??
                        const TextStyle(),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
