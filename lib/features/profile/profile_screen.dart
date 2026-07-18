import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scroll_behavior.dart';
import '../../app/theme/app_theme.dart';
import '../../core/domain/content_state.dart';
import '../../core/domain/profile.dart';
import '../../core/widgets/widgets.dart';
import '../feed/post_card.dart';
import 'profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.login});

  final String? login;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadPublicProfile();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.login != oldWidget.login) _loadPublicProfile();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _loadPublicProfile() {
    final login = widget.login;
    if (login == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(profileControllerProvider.notifier).load(login);
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 720) {
      ref.read(profileControllerProvider.notifier).paginate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final login = widget.login;
    return Scaffold(
      appBar: AppTopBar(
        title: login == null ? 'Профиль' : '@$login',
        leading: login == null
            ? null
            : IconButton(
                tooltip: 'Назад',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.goNamed('feed');
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
      ),
      body: login == null
          ? StateView.unauthorized(
              title: 'Войдите через Twitch',
              body:
                  'Для профиля владельца нужен mobile session exchange от '
                  'backend eblo.id.',
              actionLabel: 'Открыть требования входа',
              onAction: () => context.pushNamed('auth-twitch'),
            )
          : _PublicProfileBody(
              login: login,
              state: ref.watch(profileControllerProvider),
              scrollController: _scrollController,
            ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) context.goNamed('feed');
          if (index == 1) context.goNamed('videos');
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

class _PublicProfileBody extends ConsumerWidget {
  const _PublicProfileBody({
    required this.login,
    required this.state,
    required this.scrollController,
  });

  final String login;
  final ProfileControllerState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(profileControllerProvider.notifier);
    if (state.items.isEmpty) {
      if (state.phase == LoadPhase.initialLoading ||
          state.phase == LoadPhase.refreshing) {
        return const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Публикации профиля загружаются',
          ),
        );
      }
      if (state.phase == LoadPhase.empty) {
        return StateView.empty(
          title: 'Публикаций нет',
          body:
              'Публичный API не отличает пустой профиль от отсутствующего. '
              'Metadata появятся после PROFILE-01.',
          actionLabel: 'Обновить',
          onAction: () => controller.load(login),
        );
      }
      if (state.phase == LoadPhase.offlineEmpty) {
        return StateView(
          variant: StateViewVariant.offlineEmpty,
          title: 'Нет подключения',
          body: 'Сохранённых публикаций этого профиля пока нет.',
          actionLabel: 'Повторить',
          onAction: () => controller.load(login),
          icon: Icons.cloud_off_outlined,
        );
      }
      if (state.phase == LoadPhase.fatalError) {
        return StateView(
          variant: StateViewVariant.fatalError,
          title: isValidProfileLogin(login)
              ? 'Профиль @$login пока недоступен'
              : 'Некорректный логин профиля',
          body: state.failure?.message ?? 'Публичный профиль недоступен.',
          actionLabel: 'Вернуться в ленту',
          onAction: () => context.goNamed('feed'),
          icon: Icons.person_search_outlined,
        );
      }
      return StateView.error(
        title: 'Не удалось загрузить профиль',
        body: state.failure?.message ?? 'Повторите попытку.',
        actionLabel: 'Повторить',
        onAction: () => controller.load(login),
      );
    }

    final owner = state.inferredOwner;
    return RefreshIndicator(
      onRefresh: () => controller.load(login),
      child: CustomScrollView(
        controller: scrollController,
        physics: appAlwaysScrollablePhysics,
        slivers: [
          if (state.phase == LoadPhase.refreshing)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                semanticsLabel: 'Профиль обновляется',
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: context.appColors.divider,
                    backgroundImage: appImageProvider(owner?.avatarUrl),
                    child: owner?.avatarUrl == null
                        ? const Icon(Icons.person_outline_rounded)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner?.displayName ?? '@$login',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '@$login · публикаций: ${state.total}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.appColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) =>
                PostCard(post: state.items[index], onVote: (_) {}),
          ),
          SliverToBoxAdapter(
            child: _PaginationFooter(
              state: state,
              onRetry: controller.paginate,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.state, required this.onRetry});

  final ProfileControllerState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.phase == LoadPhase.paginating) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Загружаются следующие публикации',
          ),
        ),
      );
    }
    if (state.paginationFailure != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Повторить загрузку'),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
