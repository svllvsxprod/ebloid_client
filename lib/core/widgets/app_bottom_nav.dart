import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

@immutable
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.enabled = true,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool enabled;
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
    return Material(
      color: colors.surface.withValues(alpha: .94),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
              child: Row(
                children: [
                  for (var index = 0; index < items.length; index++)
                    Expanded(
                      child: _AppBottomNavTile(
                        item: items[index],
                        selected: index == selectedIndex,
                        colors: colors,
                        textStyle: text.labelSmall,
                        onTap: items[index].enabled
                            ? () => onDestinationSelected(index)
                            : null,
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

class _AppBottomNavTile extends StatelessWidget {
  const _AppBottomNavTile({
    required this.item,
    required this.selected,
    required this.colors,
    required this.textStyle,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final AppColors colors;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? colors.fg : colors.muted;
    return Semantics(
      enabled: item.enabled,
      button: true,
      selected: selected,
      label: item.enabled
          ? item.label
          : '${item.label}. Раздел пока недоступен',
      child: InkResponse(
        onTap: onTap,
        radius: AppSpacing.target / 2,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.target),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? colors.fg : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 3),
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 21,
                color: item.enabled
                    ? color
                    : colors.muted.withValues(alpha: .55),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle?.copyWith(
                  color: item.enabled
                      ? color
                      : colors.muted.withValues(alpha: .55),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
