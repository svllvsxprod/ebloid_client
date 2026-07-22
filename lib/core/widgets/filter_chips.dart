import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

@immutable
class AppFilterChipData<T> {
  const AppFilterChipData({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

class HorizontalFilterChips<T> extends StatelessWidget {
  const HorizontalFilterChips({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.semanticLabel,
  });

  final List<AppFilterChipData<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      container: true,
      label: semanticLabel ?? 'Фильтры',
      child: SizedBox(
        height: AppSpacing.target,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = item.value == selectedValue;
            return Semantics(
              button: true,
              selected: selected,
              label: item.label,
              child: FilterChip(
                selected: selected,
                showCheckmark: false,
                selectedColor: colors.soft,
                backgroundColor: colors.surfaceElevated,
                side: BorderSide(
                  color: selected ? colors.accent : colors.divider,
                ),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colors.accent : colors.muted,
                  fontWeight: FontWeight.w600,
                ),
                avatar: item.icon == null
                    ? null
                    : Icon(
                        item.icon,
                        size: 18,
                        color: selected ? colors.accent : colors.muted,
                      ),
                label: Text(item.label),
                onSelected: (_) => onSelected(item.value),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
          itemCount: items.length,
        ),
      ),
    );
  }
}
