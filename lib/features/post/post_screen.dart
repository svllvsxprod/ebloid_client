import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/domain/content_state.dart';
import '../../core/domain/post.dart';
import '../../core/domain/profile.dart';
import '../../core/platform/platform_adapters.dart';
import '../../core/widgets/widgets.dart';
import 'comment_thread.dart';
import 'post_controller.dart';
import 'post_media.dart';

class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({super.key, required this.shortCode});

  final String shortCode;

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(postControllerProvider.notifier).load(widget.shortCode);
    });
  }

  @override
  void didUpdateWidget(covariant PostScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortCode != widget.shortCode) {
      ref.read(postControllerProvider.notifier).load(widget.shortCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postControllerProvider);
    final canComment =
        state.phase == LoadPhase.success &&
        state.detail?.summary.permissions.canComment == true;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppTopBar(
        title: 'Публикация',
        leading: IconButton(
          tooltip: 'Назад к ленте',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('feed');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          if (state.detail?.summary.permissions.canShare == true)
            IconButton(
              tooltip: 'Поделиться',
              onPressed: () => _share(state.detail!.summary.shortCode),
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      body: _PostBody(state: state, shortCode: widget.shortCode),
      bottomNavigationBar: canComment ? const _CommentComposer() : null,
    );
  }

  Future<void> _share(String shortCode) async {
    try {
      await ref
          .read(shareAdapterProvider)
          .sharePost(
            shortCode,
            sharePositionOrigin: sharePositionOriginOf(context),
          );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть меню «Поделиться».')),
      );
    }
  }
}

class _PostBody extends ConsumerWidget {
  const _PostBody({required this.state, required this.shortCode});

  final PostControllerState state;
  final String shortCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(postControllerProvider.notifier);
    if (state.phase == LoadPhase.initialLoading) {
      return const SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: AppSpacing.xl),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: MediaShell.detail(),
            ),
          ],
        ),
      );
    }
    if (state.phase == LoadPhase.restricted) {
      return const StateView.restricted(
        title: 'Контент ограничен',
        body:
            'Медиа скрыто согласно состоянию публикации. Это не разрешение 18+ контента.',
      );
    }
    if (state.phase == LoadPhase.unauthorized) {
      return const StateView.unauthorized(
        title: 'Требуется вход',
        body: 'Twitch OAuth будет подключён после согласования AUTH-01.',
      );
    }
    if (state.phase == LoadPhase.fatalError) {
      return StateView(
        variant: StateViewVariant.fatalError,
        title: 'Публикация недоступна',
        body: state.failure?.message ?? 'Безопасно вернитесь в ленту.',
        icon: Icons.report_gmailerrorred_outlined,
      );
    }
    final detail = state.detail;
    if (detail == null) {
      if (state.phase == LoadPhase.offlineEmpty) {
        return StateView(
          variant: StateViewVariant.offlineEmpty,
          title: 'Нет подключения',
          body: 'Сохранённой публикации пока нет.',
          actionLabel: 'Повторить',
          onAction: () => controller.load(shortCode),
          icon: Icons.cloud_off_outlined,
        );
      }
      return StateView.error(
        title: 'Публикация недоступна',
        body: state.failure?.message ?? 'Не удалось получить публикацию.',
        actionLabel: 'Повторить',
        onAction: () => controller.load(shortCode),
      );
    }
    return Column(
      children: [
        if (state.phase == LoadPhase.refreshing)
          const LinearProgressIndicator(
            semanticsLabel: 'Публикация обновляется',
          ),
        if (state.phase == LoadPhase.offlineWithCache)
          OfflineBanner(
            message: 'Показана сохранённая публикация',
            onRetry: () => controller.load(shortCode),
          ),
        if (state.phase == LoadPhase.recoverableError)
          _PostStatusBanner(
            message:
                state.failure?.message ?? 'Не удалось обновить публикацию.',
            onRetry: () => controller.load(shortCode),
          ),
        Expanded(
          child: RefreshIndicator(
            key: const Key('post-refresh'),
            onRefresh: () => controller.load(shortCode),
            child: _PostContent(detail: detail),
          ),
        ),
      ],
    );
  }
}

class _PostStatusBanner extends StatelessWidget {
  const _PostStatusBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Ошибка обновления. $message',
      child: Material(
        color: context.appColors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: Text(message)),
              TextButton(onPressed: onRetry, child: const Text('Повторить')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostContent extends ConsumerStatefulWidget {
  const _PostContent({required this.detail});

  final PostDetail detail;

  @override
  ConsumerState<_PostContent> createState() => _PostContentState();
}

class _PostContentState extends ConsumerState<_PostContent> {
  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final post = detail.summary;
    final colors = context.appColors;
    final comments = detail.comments;
    final canOpenProfile = isValidProfileLogin(post.author.id);
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl * 4),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Semantics(
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
                        backgroundImage: appImageProvider(
                          post.author.avatarUrl,
                        ),
                        child: post.author.avatarUrl == null
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${post.createdAt.day.toString().padLeft(2, '0')}.'
                              '${post.createdAt.month.toString().padLeft(2, '0')}.'
                              '${post.createdAt.year}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        PostMedia(post: post),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 25,
                  height: 1.12,
                  letterSpacing: -.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (post.description.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  post.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.muted,
                    height: 1.58,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              VoteControl(
                score: post.counters.score,
                reaction: post.userReaction,
                onVote: post.permissions.canReact
                    ? ref.read(postControllerProvider.notifier).react
                    : null,
              ),
              CounterActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Комментарии',
                count: post.counters.comments,
              ),
              CounterActionButton(
                icon: Icons.visibility_outlined,
                label: 'Просмотры',
                count: post.counters.views,
              ),
            ],
          ),
        ),
        Divider(color: colors.divider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Комментарии · ${post.counters.comments}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: .1,
            ),
          ),
        ),
        if (detail.commentsFailure case final failure?)
          SizedBox(
            height: 300,
            child: StateView.error(
              title: 'Комментарии не загрузились',
              body: failure.message,
              actionLabel: 'Повторить',
              onAction: () => ref
                  .read(postControllerProvider.notifier)
                  .load(post.shortCode),
            ),
          )
        else if (comments.isEmpty && post.counters.comments > 0)
          SizedBox(
            height: 300,
            child: StateView.error(
              title: 'Комментарии не загрузились',
              body:
                  'Счётчик показывает ${post.counters.comments}, но список пуст.',
              actionLabel: 'Повторить',
              onAction: () => ref
                  .read(postControllerProvider.notifier)
                  .load(post.shortCode),
            ),
          )
        else if (comments.isEmpty)
          const SizedBox(
            height: 220,
            child: StateView.empty(
              title: 'Комментариев пока нет',
              body: 'Начните обсуждение публикации.',
            ),
          )
        else
          for (final comment in comments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: CommentThread(comment: comment),
            ),
      ],
    );
  }
}

class _CommentComposer extends ConsumerStatefulWidget {
  const _CommentComposer();

  @override
  ConsumerState<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<_CommentComposer> {
  final _textController = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Material(
          color: context.appColors.surface,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_sending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Написать комментарий',
                      semanticCounterText: 'Черновик комментария',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  tooltip: 'Отправить комментарий',
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final body = _textController.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    await ref.read(postControllerProvider.notifier).addComment(body);
    if (!mounted) return;
    final state = ref.read(postControllerProvider);
    setState(() => _sending = false);
    if (state.pendingCommentBody.isEmpty) {
      _textController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Комментарий отправлен')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.failure?.message ?? 'Ошибка отправки')),
      );
    }
  }
}
