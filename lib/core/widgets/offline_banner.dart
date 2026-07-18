import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.message,
    this.updatedAtLabel,
    this.onRetry,
  });

  final String message;
  final String? updatedAtLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      label: '$message${updatedAtLabel == null ? '' : '. $updatedAtLabel'}',
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.controlBorder),
          borderRadius: AppRadius.control,
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 20, color: colors.muted),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                updatedAtLabel == null ? message : '$message · $updatedAtLabel',
                style: text.bodySmall?.copyWith(color: colors.muted),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
