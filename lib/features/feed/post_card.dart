import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/domain/post.dart';
import '../../core/domain/profile.dart';
import '../../core/platform/platform_adapters.dart';
import '../../core/widgets/widgets.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post, required this.onVote});

  final PostSummary post;
  final ValueChanged<Reaction>? onVote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Публикация ${post.title}, автор ${post.author.displayName}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorRow(post: post),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              borderRadius: AppRadius.media,
              onTap: () => _openPost(context),
              child: _FeedMedia(post: post),
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () => _openPost(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (post.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      post.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(color: colors.muted),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                VoteControl(
                  score: post.counters.score,
                  reaction: post.userReaction,
                  onVote: post.permissions.canReact ? onVote : null,
                ),
                const Spacer(),
                CounterActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Комментарии',
                  count: post.counters.comments,
                  onPressed: () => _openPost(context),
                ),
                CounterActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'Просмотры',
                  count: post.counters.views,
                ),
                if (post.permissions.canShare)
                  IconButton(
                    tooltip: 'Поделиться',
                    onPressed: () => _share(context, ref),
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
              ],
            ),
            Divider(height: 1, color: colors.divider),
          ],
        ),
      ),
    );
  }

  void _openPost(BuildContext context) {
    context.pushNamed('post', pathParameters: {'shortCode': post.shortCode});
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(shareAdapterProvider)
          .sharePost(
            post.shortCode,
            sharePositionOrigin: sharePositionOriginOf(context),
          );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть меню «Поделиться».')),
      );
    }
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final avatarUrl = post.author.avatarUrl;
    final currentProfileLogin = GoRouterState.of(
      context,
    ).pathParameters['login'];
    final canOpenProfile =
        isValidProfileLogin(post.author.id) &&
        currentProfileLogin != post.author.id;
    return Semantics(
      button: canOpenProfile,
      label: canOpenProfile
          ? 'Открыть профиль ${post.author.displayName}'
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canOpenProfile
              ? () => context.pushNamed(
                  'public-profile',
                  pathParameters: {'login': post.author.id},
                )
              : null,
          borderRadius: AppRadius.control,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.divider,
                  backgroundImage: appImageProvider(avatarUrl),
                  child: avatarUrl == null
                      ? Text(post.author.displayName.characters.first)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        [
                          _dateLabel(post.createdAt),
                          if (post.isStreamSafe case final streamSafe?)
                            streamSafe ? 'для стрима' : 'не для стрима',
                        ].join(' · '),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _FeedMedia extends StatelessWidget {
  const _FeedMedia({required this.post});

  final PostSummary post;

  @override
  Widget build(BuildContext context) {
    if (post.availability == PostAvailability.restricted) {
      return const MediaShell.feed(
        placeholderKind: MediaPlaceholderKind.restricted,
        title: 'Контент ограничен',
        body: 'Медиа не загружается до подтверждения.',
      );
    }
    final item = post.media.flattened.first;
    return MediaShell.feed(
      title: item.semanticLabel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (post.media.kind == MediaKind.audio)
            ColoredBox(
              color: context.appColors.soft,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 64,
                      color: context.appColors.accent,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Аудиозапись',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AppMediaImage(
              networkUrl: item.previewUrl,
              semanticLabel: item.semanticLabel,
              fit: BoxFit.cover,
            ),
          if (post.media.kind != MediaKind.image)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.appColors.fg.withValues(alpha: .76),
                    borderRadius: AppRadius.control,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _kindIcon(post.media.kind),
                          size: 16,
                          color: context.appColors.surface,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          _kindLabel(post.media),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: context.appColors.surface),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _kindIcon(MediaKind kind) => switch (kind) {
    MediaKind.image => Icons.image_outlined,
    MediaKind.video => Icons.play_arrow_rounded,
    MediaKind.audio => Icons.graphic_eq_rounded,
    MediaKind.album => Icons.collections_outlined,
  };

  String _kindLabel(MediaAsset media) => switch (media.kind) {
    MediaKind.image => 'Изображение',
    MediaKind.video => 'Видео',
    MediaKind.audio => 'Аудио',
    MediaKind.album => 'Альбом · ${media.items.length}',
  };
}
