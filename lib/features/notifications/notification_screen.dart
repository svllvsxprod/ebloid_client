import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scroll_behavior.dart';
import '../../app/theme/app_theme.dart';
import '../../core/domain/content_state.dart';
import '../../core/domain/notification.dart';
import '../../core/platform/platform_adapters.dart';
import '../../core/widgets/widgets.dart';
import 'notification_controller.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  var _navigationInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(notificationControllerProvider);
      if (state.phase == LoadPhase.initialLoading && state.items.isEmpty) {
        ref.read(notificationControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationControllerProvider);
    final notifier = ref.read(notificationControllerProvider.notifier);
    return Scaffold(
      appBar: AppTopBar(
        title: 'Уведомления',
        subtitle: state.items.isEmpty
            ? null
            : 'Непрочитанных: ${state.unreadCount}',
        actions: [
          IconButton(
            tooltip: 'Настройки уведомлений',
            onPressed: () => context.pushNamed('settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          if (state.items.isNotEmpty)
            IconButton(
              tooltip: 'Прочитать все',
              onPressed: state.unreadCount == 0 || state.actionInProgress
                  ? null
                  : () => _markAllOpened(notifier),
              icon: const Icon(Icons.done_all_rounded),
            ),
          if (state.items.isNotEmpty)
            IconButton(
              tooltip: 'Очистить уведомления',
              onPressed: state.actionInProgress
                  ? null
                  : () => _confirmClear(notifier),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: _NotificationBody(
        state: state,
        navigationInProgress: _navigationInProgress,
        onOpen: _openNotification,
      ),
    );
  }

  Future<void> _markAllOpened(NotificationController notifier) async {
    final succeeded = await notifier.markAllOpened();
    if (!mounted || succeeded) return;
    _showActionFailure();
  }

  Future<void> _confirmClear(NotificationController notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить уведомления?'),
        content: const Text(
          'Список уведомлений будет очищен на всех устройствах. '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final succeeded = await notifier.clearAll();
    if (!mounted || succeeded) return;
    _showActionFailure();
  }

  void _showActionFailure() {
    final failure = ref.read(notificationControllerProvider).actionFailure;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure?.message ?? 'Повторите действие.')),
    );
  }

  Future<void> _openNotification(NotificationItem item) async {
    if (_navigationInProgress) return;
    setState(() => _navigationInProgress = true);
    final notifier = ref.read(notificationControllerProvider.notifier);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final externalUrlAdapter = ref.read(externalUrlAdapterProvider);
    final target = item.target;
    try {
      final marked = await notifier.markOpened(item);
      if (!marked && messenger.mounted) {
        final failure = ref.read(notificationControllerProvider).actionFailure;
        messenger.showSnackBar(
          SnackBar(content: Text(failure?.message ?? 'Повторите действие.')),
        );
      }

      final location = target?.appLocation;
      if (location != null) {
        await _pushNativeTarget(router, location);
        return;
      }
      final uri = target?.externalUri;
      if (uri == null) return;
      try {
        await externalUrlAdapter.open(uri);
      } on Object {
        if (!messenger.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку.')),
        );
      }
    } finally {
      if (mounted) setState(() => _navigationInProgress = false);
    }
  }
}

class _NotificationBody extends ConsumerWidget {
  const _NotificationBody({
    required this.state,
    required this.navigationInProgress,
    required this.onOpen,
  });

  final NotificationControllerState state;
  final bool navigationInProgress;
  final ValueChanged<NotificationItem> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationControllerProvider.notifier);
    if (state.items.isEmpty) {
      if (state.phase == LoadPhase.initialLoading ||
          state.phase == LoadPhase.refreshing) {
        return const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Уведомления загружаются',
          ),
        );
      }
      if (state.phase == LoadPhase.empty) {
        return StateView.empty(
          title: 'Уведомлений пока нет',
          body:
              'Новые реакции, комментарии и системные сообщения появятся здесь.',
          actionLabel: 'Обновить',
          onAction: notifier.load,
          icon: Icons.notifications_none_rounded,
        );
      }
      if (state.phase == LoadPhase.unauthorized) {
        return StateView.unauthorized(
          title: 'Войдите через Twitch',
          body: 'После входа приложение загрузит ваши уведомления.',
          actionLabel: 'Войти',
          onAction: () async {
            await context.pushNamed('auth-twitch');
            await notifier.load();
          },
        );
      }
      if (state.phase == LoadPhase.offlineEmpty) {
        return StateView(
          variant: StateViewVariant.offlineEmpty,
          title: 'Нет подключения',
          body: state.failure?.message ?? 'Уведомления не удалось загрузить.',
          actionLabel: 'Повторить',
          onAction: notifier.load,
          icon: Icons.cloud_off_outlined,
        );
      }
      if (state.failure?.code == 'notification_repository_missing') {
        return const StateView.unavailable(
          title: 'Уведомления пока не подключены',
          body: 'Сейчас приложение не загружает и не показывает уведомления.',
          icon: Icons.notifications_none_rounded,
        );
      }
      if (state.phase == LoadPhase.fatalError) {
        return StateView(
          variant: StateViewVariant.fatalError,
          title: 'Уведомления недоступны',
          body: state.failure?.message ?? 'Безопасно вернитесь позже.',
          icon: Icons.report_gmailerrorred_outlined,
        );
      }
      return StateView.error(
        title: 'Не удалось загрузить уведомления',
        body: state.failure?.message ?? 'Повторите попытку.',
        actionLabel: 'Повторить',
        onAction: notifier.load,
      );
    }

    final items = state.visibleItems;
    return RefreshIndicator(
      onRefresh: notifier.load,
      child: CustomScrollView(
        physics: appAlwaysScrollablePhysics,
        slivers: [
          if (state.phase == LoadPhase.refreshing)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                semanticsLabel: 'Уведомления обновляются',
              ),
            ),
          if (state.phase == LoadPhase.offlineWithCache)
            SliverToBoxAdapter(
              child: OfflineBanner(
                message: 'Не удалось обновить уведомления',
                onRetry: notifier.load,
              ),
            ),
          if (state.failure != null && state.phase == LoadPhase.success)
            SliverToBoxAdapter(
              child: _RefreshFailureBanner(
                message: state.failure!.message,
                onRetry: notifier.load,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: HorizontalFilterChips<NotificationCategory>(
                items: [
                  for (final category in NotificationCategory.values)
                    AppFilterChipData(value: category, label: category.label),
                ],
                selectedValue: state.category,
                onSelected: notifier.selectCategory,
              ),
            ),
          ),
          if (items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: StateView.empty(
                title: 'В этой категории пусто',
                body: 'Попробуйте выбрать другую категорию.',
              ),
            )
          else
            SliverList.separated(
              itemCount: items.length,
              itemBuilder: (context, index) => _NotificationTile(
                item: items[index],
                actionInProgress:
                    state.actionInProgress || navigationInProgress,
                onOpen: onOpen,
              ),
              separatorBuilder: (_, _) => const Divider(height: 1),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.actionInProgress,
    required this.onOpen,
  });

  final NotificationItem item;
  final bool actionInProgress;
  final ValueChanged<NotificationItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final target = item.target;
    return Semantics(
      container: true,
      button: target != null || !item.isRead,
      label:
          '${item.isRead ? 'Прочитано' : 'Не прочитано'}. '
          '${item.title}. ${item.message}',
      child: Material(
        color: item.isRead ? Colors.transparent : colors.soft,
        child: InkWell(
          onTap: actionInProgress || (item.isRead && target == null)
              ? null
              : () => onOpen(item),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(_kindIcon(item.kind), color: colors.accent),
                      ),
                      if (!item.isRead)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.surface),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          item.message,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: colors.muted),
                        ),
                        if (item.createdAt case final createdAt?) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _timestamp(createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (target != null)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.xs, top: 12),
                      child: Icon(Icons.chevron_right_rounded),
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

class _RefreshFailureBanner extends StatelessWidget {
  const _RefreshFailureBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Не удалось обновить уведомления. $message',
      child: Material(
        color: context.appColors.surfaceElevated,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: context.appColors.danger,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
              TextButton(onPressed: onRetry, child: const Text('Повторить')),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Object?> _pushNativeTarget(GoRouter router, String location) {
  final segments = Uri.parse(location).pathSegments;
  if (segments.length == 2 && segments.first == 'post') {
    return router.pushNamed('post', pathParameters: {'shortCode': segments[1]});
  }
  if (segments.length == 4 &&
      segments.first == 'post' &&
      segments[2] == 'comment') {
    return router.pushNamed(
      'post-comment',
      pathParameters: {'shortCode': segments[1], 'commentId': segments[3]},
    );
  }
  if (segments.length == 2 && segments.first == 'profile') {
    return router.pushNamed(
      'public-profile',
      pathParameters: {'login': segments[1]},
    );
  }
  return router.push(location);
}

IconData _kindIcon(NotificationKind kind) => switch (kind) {
  NotificationKind.commentReply ||
  NotificationKind.postComment => Icons.chat_bubble_outline_rounded,
  NotificationKind.commentPinned => Icons.push_pin_outlined,
  NotificationKind.postLike => Icons.arrow_upward_rounded,
  NotificationKind.videoApproved => Icons.task_alt_rounded,
  NotificationKind.videoRejected => Icons.block_rounded,
  NotificationKind.videoViewed => Icons.smart_display_outlined,
  NotificationKind.adminBroadcast => Icons.campaign_outlined,
  NotificationKind.system ||
  NotificationKind.unknown => Icons.info_outline_rounded,
};

String _timestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} · $hour:$minute';
}
