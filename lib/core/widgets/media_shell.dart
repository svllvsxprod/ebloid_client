import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum MediaShellAspect { feed, detail }

enum MediaPlaceholderKind { loading, error, restricted }

class MediaShell extends StatelessWidget {
  const MediaShell({
    super.key,
    required this.aspect,
    this.child,
    this.placeholderKind,
    this.title,
    this.body,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.borderRadius,
    this.aspectRatio,
  });

  const MediaShell.feed({
    super.key,
    this.child,
    this.placeholderKind,
    this.title,
    this.body,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.borderRadius = AppRadius.media,
    this.aspectRatio,
  }) : aspect = MediaShellAspect.feed;

  const MediaShell.detail({
    super.key,
    this.child,
    this.placeholderKind,
    this.title,
    this.body,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.borderRadius = BorderRadius.zero,
    this.aspectRatio,
  }) : aspect = MediaShellAspect.detail;

  final MediaShellAspect aspect;
  final Widget? child;
  final MediaPlaceholderKind? placeholderKind;
  final String? title;
  final String? body;
  final VoidCallback? onRetry;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final BorderRadius? borderRadius;
  final double? aspectRatio;

  double get _ratio =>
      aspectRatio ??
      switch (aspect) {
        MediaShellAspect.feed => 16 / 10,
        MediaShellAspect.detail => 16 / 11,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      container: true,
      label: title ?? 'Медиа публикации',
      child: AspectRatio(
        aspectRatio: _ratio,
        child: Container(
          foregroundDecoration: BoxDecoration(
            border: Border.all(color: colors.divider),
            borderRadius: borderRadius ?? BorderRadius.zero,
          ),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.zero,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: child == null ? colors.soft : colors.mediaBackdrop,
              ),
              child:
                  child ??
                  _MediaPlaceholder(
                    kind: placeholderKind ?? MediaPlaceholderKind.loading,
                    title: title,
                    body: body,
                    onRetry: onRetry,
                    secondaryActionLabel: secondaryActionLabel,
                    onSecondaryAction: onSecondaryAction,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

double detailMediaAspectRatio(double? sourceRatio) {
  if (sourceRatio == null || !sourceRatio.isFinite || sourceRatio <= 0) {
    return 16 / 11;
  }
  return sourceRatio.clamp(9 / 16, 21 / 9).toDouble();
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({
    required this.kind,
    this.title,
    this.body,
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final MediaPlaceholderKind kind;
  final String? title;
  final String? body;
  final VoidCallback? onRetry;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final defaultTitle = switch (kind) {
      MediaPlaceholderKind.loading => 'Медиа загружается',
      MediaPlaceholderKind.error => 'Не удалось загрузить медиа',
      MediaPlaceholderKind.restricted => 'Медиа ограничено',
    };
    final icon = switch (kind) {
      MediaPlaceholderKind.loading => Icons.image_outlined,
      MediaPlaceholderKind.error => Icons.refresh,
      MediaPlaceholderKind.restricted => Icons.visibility_off_outlined,
    };

    return Semantics(
      liveRegion: kind != MediaPlaceholderKind.loading,
      label: '${title ?? defaultTitle}${body == null ? '' : '. $body'}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.muted),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title ?? defaultTitle,
                textAlign: TextAlign.center,
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: colors.muted),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton(onPressed: onRetry, child: const Text('Повторить')),
              ],
              if (onSecondaryAction != null &&
                  secondaryActionLabel != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                TextButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryActionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
