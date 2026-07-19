import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scroll_behavior.dart';
import '../../app/theme/app_theme.dart';
import '../../core/domain/content_state.dart';
import '../../core/domain/feed.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_controller.dart';
import 'feed_controller.dart';
import 'post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(feedControllerProvider);
      if (state.items.isEmpty && state.phase == LoadPhase.initialLoading) {
        ref.read(feedControllerProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 720) {
      ref.read(feedControllerProvider.notifier).paginate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider);
    final controller = ref.read(feedControllerProvider.notifier);
    final streamFilterEnabled = ref.watch(feedStreamSafeFilterEnabledProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    return Scaffold(
      appBar: AppTopBar(
        title: 'eblo.id',
        actions: [
          IconButton(
            tooltip: 'Поиск',
            onPressed: () => context.pushNamed('search'),
            icon: const Icon(Icons.search_rounded),
          ),
          Semantics(
            label: 'Открыть профиль',
            button: true,
            child: InkWell(
              onTap: () => context.goNamed('profile'),
              borderRadius: AppRadius.control,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: CircleAvatar(
                  radius: 17,
                  backgroundImage: appImageProvider(currentUser?.avatarUrl),
                  child: currentUser == null
                      ? const Icon(Icons.person_outline_rounded)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: _SortSegment(
              selected: state.query.sort,
              onSelected: (value) =>
                  controller.load(query: state.query.copyWith(sort: value)),
            ),
          ),
          HorizontalFilterChips<FeedMediaType>(
            semanticLabel: 'Тип публикации',
            items: const [
              AppFilterChipData(value: FeedMediaType.all, label: 'Всё'),
              AppFilterChipData(
                value: FeedMediaType.image,
                label: 'Изображения',
                icon: Icons.image_outlined,
              ),
              AppFilterChipData(
                value: FeedMediaType.video,
                label: 'Видео',
                icon: Icons.play_circle_outline,
              ),
              AppFilterChipData(
                value: FeedMediaType.audio,
                label: 'Аудио',
                icon: Icons.graphic_eq_rounded,
              ),
              AppFilterChipData(
                value: FeedMediaType.album,
                label: 'Альбомы',
                icon: Icons.collections_outlined,
              ),
            ],
            selectedValue: state.query.type,
            onSelected: (value) =>
                controller.load(query: state.query.copyWith(type: value)),
          ),
          if (state.query.sort != FeedSort.newest)
            HorizontalFilterChips<FeedPeriod>(
              semanticLabel: 'Период публикаций',
              items: const [
                AppFilterChipData(value: FeedPeriod.today, label: 'Сегодня'),
                AppFilterChipData(value: FeedPeriod.week, label: 'Неделя'),
                AppFilterChipData(value: FeedPeriod.month, label: 'Месяц'),
                AppFilterChipData(value: FeedPeriod.year, label: 'Год'),
                AppFilterChipData(
                  value: FeedPeriod.allTime,
                  label: 'Всё время',
                ),
              ],
              selectedValue: state.query.period,
              onSelected: (value) =>
                  controller.load(query: state.query.copyWith(period: value)),
            ),
          if (streamFilterEnabled)
            Semantics(
              label: 'Фильтр только для стрима',
              toggled: state.query.streamSafeOnly,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Только для стрима',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Switch(
                      value: state.query.streamSafeOnly,
                      onChanged: (value) => controller.load(
                        query: state.query.copyWith(streamSafeOnly: value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _FeedBody(state: state, scrollController: _scrollController),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Создать пост',
        onPressed: () => context.pushNamed('create'),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.goNamed('videos');
          if (index == 2) context.goNamed('profile');
        },
        items: const [
          AppBottomNavItem(
            icon: Icons.dynamic_feed_outlined,
            selectedIcon: Icons.dynamic_feed_rounded,
            label: 'Лента',
          ),
          AppBottomNavItem(
            icon: Icons.smart_display_outlined,
            selectedIcon: Icons.smart_display_rounded,
            label: 'Видео',
          ),
          AppBottomNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class _SortSegment extends StatelessWidget {
  const _SortSegment({required this.selected, required this.onSelected});

  final FeedSort selected;
  final ValueChanged<FeedSort> onSelected;

  static const _primary = [FeedSort.best, FeedSort.newest];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selectedIsOverflow = !_primary.contains(selected);
    return Semantics(
      container: true,
      label: 'Сортировка ленты',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.soft,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              for (final sort in _primary)
                Expanded(
                  child: _SegmentButton(
                    label: _sortLabel(sort),
                    selected: selected == sort,
                    onTap: () => onSelected(sort),
                  ),
                ),
              SizedBox(
                width: AppSpacing.target,
                height: AppSpacing.target,
                child: PopupMenuButton<FeedSort>(
                  tooltip: 'Дополнительные сортировки',
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: selectedIsOverflow ? colors.fg : colors.muted,
                  ),
                  onSelected: onSelected,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: FeedSort.views,
                      child: Text('Просмотры'),
                    ),
                    PopupMenuItem(
                      value: FeedSort.score,
                      child: Text('По лайкам'),
                    ),
                    PopupMenuItem(
                      value: FeedSort.comments,
                      child: Text('По комментариям'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _sortLabel(FeedSort sort) => switch (sort) {
    FeedSort.best => 'Лучшее',
    FeedSort.newest => 'Новое',
    FeedSort.views => 'Просмотры',
    FeedSort.score => 'Рейтинг',
    FeedSort.comments => 'Комментарии',
  };
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        elevation: selected ? 1 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.target),
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colors.fg : colors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedBody extends ConsumerWidget {
  const _FeedBody({required this.state, required this.scrollController});

  final FeedControllerState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(feedControllerProvider.notifier);
    if (state.items.isEmpty) {
      return switch (state.phase) {
        LoadPhase.initialLoading || LoadPhase.refreshing => ListView(
          physics: appAlwaysScrollablePhysics,
          children: const [
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: MediaShell.feed(),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: MediaShell.feed(),
            ),
          ],
        ),
        LoadPhase.empty => _StateList(
          child: StateView.empty(
            title: 'Публикаций нет',
            body: 'Попробуйте изменить фильтры или обновить ленту.',
            actionLabel: 'Сбросить фильтры',
            onAction: () => controller.load(query: const FeedQuery()),
          ),
        ),
        LoadPhase.offlineEmpty => _StateList(
          child: StateView(
            variant: StateViewVariant.offlineEmpty,
            title: 'Нет подключения',
            body: 'Сохранённой ленты пока нет.',
            actionLabel: 'Повторить',
            onAction: controller.load,
            icon: Icons.cloud_off_outlined,
          ),
        ),
        LoadPhase.fatalError => const _StateList(
          child: StateView(
            variant: StateViewVariant.fatalError,
            title: 'Лента недоступна',
            body: 'Безопасно вернитесь позже или откройте поддержку.',
            icon: Icons.report_gmailerrorred_outlined,
          ),
        ),
        LoadPhase.unauthorized => const _StateList(
          child: StateView.unauthorized(
            title: 'Требуется вход',
            body: 'Twitch OAuth будет подключён после согласования AUTH-01.',
          ),
        ),
        LoadPhase.restricted => const _StateList(
          child: StateView.restricted(
            title: 'Лента ограничена',
            body: 'Сервер ограничил доступ к этой подборке.',
          ),
        ),
        _ => _StateList(
          child: StateView.error(
            title: 'Не удалось загрузить ленту',
            body: state.failure?.message ?? 'Повторите попытку.',
            actionLabel: 'Повторить',
            onAction: controller.load,
          ),
        ),
      };
    }

    return RefreshIndicator(
      key: const Key('feed-refresh'),
      onRefresh: controller.load,
      child: ListView.builder(
        controller: scrollController,
        key: const PageStorageKey('feed-scroll'),
        physics: appAlwaysScrollablePhysics,
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: state.items.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            if (state.phase == LoadPhase.offlineWithCache) {
              return OfflineBanner(
                message: 'Показана сохранённая лента',
                onRetry: controller.load,
              );
            }
            if (state.phase == LoadPhase.refreshing) {
              return const LinearProgressIndicator(
                semanticsLabel: 'Лента обновляется',
              );
            }
            return const SizedBox.shrink();
          }
          final postIndex = index - 1;
          if (postIndex < state.items.length) {
            final post = state.items[postIndex];
            return PostCard(
              key: ValueKey(post.id),
              post: post,
              onVote: (reaction) => controller.react(post.id, reaction),
            );
          }
          if (state.phase == LoadPhase.paginating) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.paginationFailure != null) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: OutlinedButton.icon(
                onPressed: controller.paginate,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить загрузку'),
              ),
            );
          }
          if (state.canPaginate) return const SizedBox(height: AppSpacing.xl);
          return const SizedBox(height: AppSpacing.xl);
        },
      ),
    );
  }
}

class _StateList extends StatelessWidget {
  const _StateList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: appAlwaysScrollablePhysics,
      children: [SizedBox(height: 440, child: child)],
    );
  }
}
