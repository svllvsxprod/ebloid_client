import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/domain/content_state.dart';
import '../../core/domain/post.dart';
import '../../core/domain/profile.dart';
import '../../core/domain/protected_intent.dart';
import '../../core/platform/platform_adapters.dart';
import '../../core/widgets/widgets.dart';
import '../auth/protected_intent_controller.dart';
import 'comment_thread.dart';
import 'post_controller.dart';
import 'post_media.dart';

class PostScreen extends ConsumerStatefulWidget {
  const PostScreen({
    super.key,
    required this.shortCode,
    this.focusedCommentId,
    this.restoredProtectedIntent,
  });

  final String shortCode;
  final String? focusedCommentId;
  final PendingProtectedIntent? restoredProtectedIntent;

  @override
  ConsumerState<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends ConsumerState<PostScreen> {
  String? _restoredIntentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndRestore());
  }

  @override
  void didUpdateWidget(covariant PostScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortCode != widget.shortCode) {
      _loadAndRestore();
    } else if (oldWidget.restoredProtectedIntent?.id !=
        widget.restoredProtectedIntent?.id) {
      _restoreProtectedIntent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postControllerProvider);
    final permissions = state.detail?.summary.permissions;
    final canCompose =
        state.phase == LoadPhase.success &&
        (permissions?.canComment == true ||
            permissions?.requiresAuthToComment == true);
    final replyTarget = _findCommentById(
      state.detail?.comments ?? const [],
      state.pendingReplyParentId,
    );
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
          if (state.detail?.summary.availability ==
                  PostAvailability.available &&
              state.detail?.summary.permissions.canShare == true)
            IconButton(
              tooltip: 'Поделиться',
              onPressed: () => _share(state.detail!.summary.shortCode),
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      body: _PostBody(
        state: state,
        shortCode: widget.shortCode,
        focusedCommentId: widget.focusedCommentId,
        onReply: (comment) => ref
            .read(postControllerProvider.notifier)
            .setReplyTarget(comment.id),
      ),
      bottomNavigationBar: canCompose
          ? _CommentComposer(
              shortCode: widget.shortCode,
              draftBody: state.pendingCommentBody,
              replyTarget: replyTarget,
              requiresAuth: permissions?.requiresAuthToComment == true,
            )
          : null,
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

  Future<void> _loadAndRestore() async {
    await ref.read(postControllerProvider.notifier).load(widget.shortCode);
    if (!mounted) return;
    await _restoreProtectedIntent();
  }

  Future<void> _restoreProtectedIntent() async {
    final intent = widget.restoredProtectedIntent;
    if (intent == null || intent.id == _restoredIntentId) return;
    _restoredIntentId = intent.id;
    final restored = await ref
        .read(postControllerProvider.notifier)
        .restoreProtectedIntent(intent);
    if (!mounted) return;
    final message = restored
        ? 'Черновик восстановлен. Проверьте текст и нажмите отправку.'
        : switch (intent.kind) {
            ProtectedIntentKind.postReaction ||
            ProtectedIntentKind.commentReaction =>
              'Вход выполнен. Нажмите оценку ещё раз для подтверждения.',
            _ => null,
          };
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _PostBody extends ConsumerWidget {
  const _PostBody({
    required this.state,
    required this.shortCode,
    this.focusedCommentId,
    this.onReply,
  });

  final PostControllerState state;
  final String shortCode;
  final String? focusedCommentId;
  final ValueChanged<Comment>? onReply;

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
        body: 'Войдите через Twitch и вернитесь к публикации.',
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
    final unavailableView = switch (detail.summary.availability) {
      PostAvailability.deleted => const StateView(
        variant: StateViewVariant.fatalError,
        title: 'Публикация удалена',
        body: 'Этот материал больше недоступен.',
        icon: Icons.delete_outline_rounded,
      ),
      PostAvailability.unavailable => const StateView(
        variant: StateViewVariant.fatalError,
        title: 'Публикация недоступна',
        body: 'Доступ к этому материалу отсутствует.',
        icon: Icons.block_rounded,
      ),
      PostAvailability.moderating => const StateView(
        variant: StateViewVariant.restricted,
        title: 'Публикация на проверке',
        body: 'Материал временно недоступен во время модерации.',
        icon: Icons.hourglass_top_rounded,
      ),
      PostAvailability.available || PostAvailability.restricted => null,
    };
    if (unavailableView != null) return unavailableView;
    return Column(
      children: [
        if (state.phase == LoadPhase.refreshing)
          const LinearProgressIndicator(
            semanticsLabel: 'Публикация обновляется',
          ),
        if (state.phase == LoadPhase.offlineWithCache)
          OfflineBanner(
            message: _offlinePostMessage(state.cachedAt),
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
            child: _PostContent(
              detail: detail,
              focusedCommentId: focusedCommentId,
              onReply: onReply,
            ),
          ),
        ),
      ],
    );
  }
}

String _offlinePostMessage(DateTime? cachedAt) {
  if (cachedAt == null) return 'Показана сохранённая публикация';
  final local = cachedAt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return 'Показана сохранённая публикация · данные от '
      '$day.$month $hour:$minute';
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
        color: context.appColors.surfaceElevated,
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
  const _PostContent({
    required this.detail,
    this.focusedCommentId,
    this.onReply,
  });

  final PostDetail detail;
  final String? focusedCommentId;
  final ValueChanged<Comment>? onReply;

  @override
  ConsumerState<_PostContent> createState() => _PostContentState();
}

class _PostContentState extends ConsumerState<_PostContent> {
  final _focusedCommentKey = GlobalKey();
  final _focusedCommentNode = FocusNode(debugLabel: 'focused-comment');
  String? _scheduledCommentId;

  @override
  void dispose() {
    _focusedCommentNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scheduleCommentFocus();
  }

  @override
  void didUpdateWidget(covariant _PostContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedCommentId != widget.focusedCommentId ||
        oldWidget.detail.comments != widget.detail.comments) {
      _scheduledCommentId = null;
      _scheduleCommentFocus();
    }
  }

  void _scheduleCommentFocus() {
    final id = widget.focusedCommentId;
    if (id == null || id == _scheduledCommentId) return;
    _scheduledCommentId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _focusedCommentKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        alignment: .12,
      );
      _focusedCommentNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final post = detail.summary;
    final colors = context.appColors;
    final comments = detail.comments;
    final focusedCommentFound = widget.focusedCommentId == null
        ? true
        : comments.any(
            (comment) => commentContains(comment, widget.focusedCommentId!),
          );
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
        if (!focusedCommentFound)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Text(
              'Указанный комментарий не найден.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.muted),
            ),
          ),
        PostMedia(
          post: post,
          offlineCached: detail.source == PageSource.cache,
          onOpenExternally: () => _openPostExternally(post.shortCode),
        ),
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
                onVote:
                    (post.permissions.canReact ||
                            post.permissions.requiresAuthToReact) &&
                        !ref.watch(postControllerProvider).reactionPending
                    ? _react
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
        if (detail.commentsFailure case final failure? when comments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _PostStatusBanner(
              message: failure.message,
              onRetry: () => ref
                  .read(postControllerProvider.notifier)
                  .load(post.shortCode),
            ),
          ),
        if (detail.commentsFailure case final failure? when comments.isEmpty)
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
          ),
        if (comments.isNotEmpty)
          for (final comment in comments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: CommentThread(
                comment: comment,
                focusedCommentId: widget.focusedCommentId,
                focusedCommentKey: _focusedCommentKey,
                focusedCommentNode: _focusedCommentNode,
                onReply: widget.onReply,
                onVote: _reactToComment,
              ),
            ),
      ],
    );
  }

  Future<void> _react(Reaction reaction) async {
    final post = widget.detail.summary;
    if (post.permissions.requiresAuthToReact) {
      final intent = await ref
          .read(protectedIntentControllerProvider.notifier)
          .createPostReaction(
            postShortCode: post.shortCode,
            reaction: reaction,
          );
      if (!mounted) return;
      await _openAuth(intent);
      return;
    }
    await ref.read(postControllerProvider.notifier).react(reaction);
    if (!mounted) return;
    final failure = ref.read(postControllerProvider).failure;
    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _reactToComment(Comment comment, Reaction reaction) async {
    if (comment.permissions.requiresAuthToReact) {
      final intent = await ref
          .read(protectedIntentControllerProvider.notifier)
          .createCommentReaction(
            postShortCode: widget.detail.summary.shortCode,
            commentId: comment.id,
            reaction: reaction,
          );
      if (!mounted) return;
      await _openAuth(intent);
      return;
    }
    await ref
        .read(postControllerProvider.notifier)
        .reactToComment(comment.id, reaction);
    if (!mounted) return;
    final failure = ref.read(postControllerProvider).failure;
    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _openAuth(PendingProtectedIntent intent) async {
    final restored = await context.pushNamed<PendingProtectedIntent>(
      'auth-twitch',
      queryParameters: {'intent': intent.id, 'nonce': intent.nonce},
    );
    if (!mounted || restored == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Вход выполнен. Нажмите оценку ещё раз для подтверждения.',
        ),
      ),
    );
  }

  Future<void> _openPostExternally(String shortCode) async {
    try {
      await ref
          .read(externalUrlAdapterProvider)
          .open(canonicalPostUri(shortCode));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть публикацию.')),
      );
    }
  }
}

class _CommentComposer extends ConsumerStatefulWidget {
  const _CommentComposer({
    required this.shortCode,
    required this.draftBody,
    required this.requiresAuth,
    this.replyTarget,
  });

  final String shortCode;
  final String draftBody;
  final bool requiresAuth;
  final Comment? replyTarget;

  @override
  ConsumerState<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<_CommentComposer>
    with WidgetsBindingObserver {
  late final _textController = TextEditingController(text: widget.draftBody);
  var _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant _CommentComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.draftBody != _textController.text) {
      _textController.value = TextEditingValue(
        text: widget.draftBody,
        selection: TextSelection.collapsed(offset: widget.draftBody.length),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ref.read(postControllerProvider.notifier).flushCommentDraft();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(postControllerProvider.notifier).flushCommentDraft();
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
          elevation: 0,
          shape: Border(top: BorderSide(color: context.appColors.divider)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.replyTarget case final target?)
                        InputChip(
                          label: Text(
                            'Ответ для ${target.author.displayName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: _sending
                              ? null
                              : () => ref
                                    .read(postControllerProvider.notifier)
                                    .setReplyTarget(null),
                        ),
                      TextField(
                        controller: _textController,
                        enabled: !_sending,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        onChanged: ref
                            .read(postControllerProvider.notifier)
                            .updateCommentDraft,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Написать комментарий',
                          semanticCounterText: 'Черновик комментария',
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  tooltip: widget.requiresAuth
                      ? 'Войти для отправки комментария'
                      : 'Отправить комментарий',
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          widget.requiresAuth
                              ? Icons.login_rounded
                              : Icons.send_rounded,
                        ),
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
    final controller = ref.read(postControllerProvider.notifier);
    controller.updateCommentDraft(body);
    controller.setReplyTarget(widget.replyTarget?.id);
    await controller.flushCommentDraft();
    if (widget.requiresAuth) {
      try {
        final intent = await ref
            .read(protectedIntentControllerProvider.notifier)
            .createCommentDraft(
              postShortCode: widget.shortCode,
              parentCommentId: widget.replyTarget?.id,
            );
        if (!mounted) return;
        final restored = await context.pushNamed<PendingProtectedIntent>(
          'auth-twitch',
          queryParameters: {'intent': intent.id, 'nonce': intent.nonce},
        );
        if (!mounted || restored == null) return;
        final didRestore = await controller.restoreProtectedIntent(restored);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              didRestore
                  ? 'Черновик восстановлен. Проверьте текст и нажмите отправку.'
                  : 'Вход выполнен, но черновик восстановить не удалось.',
            ),
          ),
        );
      } on Object {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось безопасно сохранить действие.'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _sending = false);
      }
      return;
    }
    await controller.addComment(body, parentId: widget.replyTarget?.id);
    if (!mounted) return;
    final state = ref.read(postControllerProvider);
    setState(() => _sending = false);
    if (state.pendingCommentBody.isEmpty) {
      _textController.clear();
      controller.setReplyTarget(null);
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

Comment? _findCommentById(List<Comment> comments, String? id) {
  if (id == null) return null;
  for (final comment in comments) {
    if (comment.id == id) return comment;
    final nested = _findCommentById(comment.replies, id);
    if (nested != null) return nested;
  }
  return null;
}
