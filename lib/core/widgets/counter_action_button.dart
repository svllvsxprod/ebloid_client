import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class CounterActionButton extends StatelessWidget {
  const CounterActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    this.onPressed,
    this.selected = false,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback? onPressed;
  final bool selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final enabled = onPressed != null;
    final fg = selected ? colors.accent : colors.muted;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: '$label: $count',
      child: Tooltip(
        message: tooltip ?? label,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: fg),
          label: Text(
            '$count',
            style: text.labelLarge
                ?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                )
                .tabularFigures,
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(AppSpacing.target, AppSpacing.target),
            foregroundColor: fg,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
      ),
    );
  }
}
