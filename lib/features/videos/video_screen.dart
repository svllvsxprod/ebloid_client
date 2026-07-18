import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scroll_behavior.dart';
import '../../app/theme/app_theme.dart';
import '../../core/domain/content_state.dart';
import '../../core/domain/video.dart';
import '../../core/widgets/widgets.dart';
import 'video_controller.dart';

class VideoScreen extends ConsumerStatefulWidget {
  const VideoScreen({super.key});

  @override
  ConsumerState<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends ConsumerState<VideoScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(videoControllerProvider);
      if (state.items.isEmpty && state.phase == LoadPhase.initialLoading) {
        ref.read(videoControllerProvider.notifier).load();
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
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 720) {
      ref.read(videoControllerProvider.notifier).paginate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoControllerProvider);
    return Scaffold(
      appBar: const AppTopBar(title: 'Видео'),
      body: _VideoBody(state: state, controller: _scrollController),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) context.goNamed('feed');
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

class _VideoBody extends ConsumerWidget {
  const _VideoBody({required this.state, required this.controller});

  final VideoControllerState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(videoControllerProvider.notifier);
    if (state.items.isEmpty) {
      if (state.phase == LoadPhase.initialLoading) {
        return const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Видео загружаются'),
        );
      }
      if (state.phase == LoadPhase.empty) {
        return const StateView.empty(
          title: 'Видео пока нет',
          body: 'Список успешно загружен, но оказался пустым.',
        );
      }
      if (state.phase == LoadPhase.offlineEmpty) {
        return StateView(
          variant: StateViewVariant.offlineEmpty,
          title: 'Нет подключения',
          body: 'Сохранённого списка видео пока нет.',
          actionLabel: 'Повторить',
          onAction: notifier.load,
          icon: Icons.cloud_off_outlined,
        );
      }
      if (state.phase == LoadPhase.fatalError) {
        return StateView(
          variant: StateViewVariant.fatalError,
          title: 'Видео недоступны',
          body: state.failure?.message ?? 'Безопасно вернитесь позже.',
          icon: Icons.report_gmailerrorred_outlined,
        );
      }
      return StateView.error(
        title: 'Не удалось загрузить видео',
        body: state.failure?.message ?? 'Повторите попытку.',
        actionLabel: 'Повторить',
        onAction: notifier.load,
      );
    }
    return RefreshIndicator(
      onRefresh: notifier.load,
      child: CustomScrollView(
        controller: controller,
        physics: appAlwaysScrollablePhysics,
        slivers: [
          if (state.phase == LoadPhase.refreshing)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                semanticsLabel: 'Список видео обновляется',
              ),
            ),
          if (state.phase == LoadPhase.offlineWithCache)
            SliverToBoxAdapter(
              child: OfflineBanner(
                message: 'Показан сохранённый список видео',
                onRetry: notifier.load,
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 58,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                itemCount: state.categories.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return Chip(
                    label: Text('${category.title} · ${category.videosCount}'),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            sliver: SliverList.separated(
              itemCount: state.items.length,
              itemBuilder: (context, index) =>
                  _VideoCard(item: state.items[index]),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
            ),
          ),
          SliverToBoxAdapter(
            child: state.phase == LoadPhase.paginating
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : state.paginationFailure != null
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: OutlinedButton.icon(
                      onPressed: notifier.paginate,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Повторить подгрузку'),
                    ),
                  )
                : const SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.item});

  final VideoItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      container: true,
      label: 'Видео ${item.title}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: AppRadius.media,
              child: AppMediaImage(
                networkUrl: item.thumbnailUrl ?? item.previewUrl,
                semanticLabel: item.title,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            [
              if (item.channelTitle?.isNotEmpty == true) item.channelTitle!,
              '${item.views} просмотров',
              '${item.votes} голосов',
            ].join(' · '),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
