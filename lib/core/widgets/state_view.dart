import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum StateViewVariant {
  empty,
  unavailable,
  offlineEmpty,
  recoverableError,
  fatalError,
  unauthorized,
  restricted,
  success,
}

class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.variant,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  const StateView.empty({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  }) : variant = StateViewVariant.empty;

  const StateView.unavailable({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.hourglass_empty_rounded,
  }) : variant = StateViewVariant.unavailable;

  const StateView.error({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.error_outline,
  }) : variant = StateViewVariant.recoverableError;

  const StateView.unauthorized({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.login,
  }) : variant = StateViewVariant.unauthorized;

  const StateView.restricted({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.visibility_off_outlined,
  }) : variant = StateViewVariant.restricted;

  final StateViewVariant variant;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final label = switch (variant) {
      StateViewVariant.empty => 'Пустое состояние',
      StateViewVariant.unavailable => 'Раздел пока недоступен',
      StateViewVariant.offlineEmpty => 'Нет сети и сохранённых данных',
      StateViewVariant.recoverableError => 'Ошибка, можно повторить',
      StateViewVariant.fatalError => 'Критическая ошибка',
      StateViewVariant.unauthorized => 'Требуется вход',
      StateViewVariant.restricted => 'Ограниченный контент',
      StateViewVariant.success => 'Готово',
    };
    final tone = switch (variant) {
      StateViewVariant.empty => colors.muted,
      StateViewVariant.unavailable => colors.info,
      StateViewVariant.offlineEmpty => colors.warning,
      StateViewVariant.recoverableError ||
      StateViewVariant.fatalError => colors.danger,
      StateViewVariant.unauthorized => colors.info,
      StateViewVariant.restricted => colors.warning,
      StateViewVariant.success => colors.success,
    };

    return Semantics(
      container: true,
      label: '$label. $title. $body',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Container(
                    width: 68,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: .1),
                      border: Border.all(color: tone.withValues(alpha: .38)),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(icon, size: 32, color: tone),
                  ),
                if (icon != null) const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: colors.muted),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
