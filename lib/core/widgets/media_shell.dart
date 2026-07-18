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
    this.borderRadius,
  });

  const MediaShell.feed({
    super.key,
    this.child,
    this.placeholderKind,
    this.title,
    this.body,
    this.onRetry,
    this.borderRadius = AppRadius.media,
  }) : aspect = MediaShellAspect.feed;

  const MediaShell.detail({
    super.key,
    this.child,
    this.placeholderKind,
    this.title,
    this.body,
    this.onRetry,
    this.borderRadius = BorderRadius.zero,
  }) : aspect = MediaShellAspect.detail;

  final MediaShellAspect aspect;
  final Widget? child;
  final MediaPlaceholderKind? placeholderKind;
  final String? title;
  final String? body;
  final VoidCallback? onRetry;
  final BorderRadius? borderRadius;

  double get _ratio => switch (aspect) {
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
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(color: colors.soft),
            child:
                child ??
                _MediaPlaceholder(
                  kind: placeholderKind ?? MediaPlaceholderKind.loading,
                  title: title,
                  body: body,
                  onRetry: onRetry,
                ),
          ),
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({
    required this.kind,
    this.title,
    this.body,
    this.onRetry,
  });

  final MediaPlaceholderKind kind;
  final String? title;
  final String? body;
  final VoidCallback? onRetry;

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
            ],
          ),
        ),
      ),
    );
  }
}
