import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_scroll_behavior.dart';
import '../../app/theme/app_theme.dart';
import '../../core/domain/content_state.dart';
import '../../core/domain/profile.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_controller.dart';
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
  String? _requestedLogin;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadPublicProfile();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.login != oldWidget.login) {
      _requestedLogin = null;
      _loadPublicProfile();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _loadPublicProfile() {
    _loadProfile(widget.login);
  }

  void _loadProfile(String? login) {
    if (login == null || login == _requestedLogin) return;
    _requestedLogin = login;
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
    final currentUser = ref.watch(currentUserProvider);
    final sessionUser = currentUser.value;
    final login = widget.login ?? sessionUser?.login;
    _loadProfile(login);
    final profileState = ref.watch(profileControllerProvider);
    final visibleState = profileState.login == login
        ? profileState
        : const ProfileControllerState.initial();
    return Scaffold(
      appBar: AppTopBar(
        title: 'Профиль',
        leading: widget.login == null
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
      body: widget.login == null && currentUser.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Загрузка профиля',
              ),
            )
          : login == null
          ? StateView.unauthorized(
              title: 'Войдите через Twitch',
              body: currentUser.hasError
                  ? 'Не удалось получить профиль активной сессии.'
                  : 'После входа здесь появятся профиль и публикации.',
              actionLabel: currentUser.hasError ? 'Повторить' : 'Войти',
              onAction: currentUser.hasError
                  ? () => ref.invalidate(currentUserProvider)
                  : () => context.pushNamed('auth-twitch'),
            )
          : _PublicProfileBody(
              login: login,
              sessionUser: widget.login == null ? sessionUser : null,
              state: visibleState,
              scrollController: _scrollController,
            ),
    );
  }
}

class _PublicProfileBody extends ConsumerWidget {
  const _PublicProfileBody({
    required this.login,
    required this.sessionUser,
    required this.state,
    required this.scrollController,
  });

  final String login;
  final SessionUser? sessionUser;
  final ProfileControllerState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(profileControllerProvider.notifier);
    Widget withSessionHeader(Widget child) {
      final user = sessionUser;
      if (user == null) return child;
      return Column(
        children: [
          _SessionProfileHeader(user: user),
          Expanded(child: child),
        ],
      );
    }

    if (state.items.isEmpty) {
      if (state.phase == LoadPhase.initialLoading ||
          state.phase == LoadPhase.refreshing) {
        return withSessionHeader(
          const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Публикации профиля загружаются',
            ),
          ),
        );
      }
      if (state.phase == LoadPhase.empty) {
        return withSessionHeader(
          StateView.empty(
            title: 'Публикаций нет',
            body:
                'Публичный API не отличает пустой профиль от отсутствующего. '
                'Metadata появятся после PROFILE-01.',
            actionLabel: 'Обновить',
            onAction: () => controller.load(login),
          ),
        );
      }
      if (state.phase == LoadPhase.offlineEmpty) {
        return withSessionHeader(
          StateView(
            variant: StateViewVariant.offlineEmpty,
            title: 'Нет подключения',
            body: 'Сохранённых публикаций этого профиля пока нет.',
            actionLabel: 'Повторить',
            onAction: () => controller.load(login),
            icon: Icons.cloud_off_outlined,
          ),
        );
      }
      if (state.phase == LoadPhase.fatalError) {
        return withSessionHeader(
          StateView(
            variant: StateViewVariant.fatalError,
            title: isValidProfileLogin(login)
                ? 'Профиль @$login пока недоступен'
                : 'Некорректный логин профиля',
            body: state.failure?.message ?? 'Публичный профиль недоступен.',
            actionLabel: 'Вернуться в ленту',
            onAction: () => context.goNamed('feed'),
            icon: Icons.person_search_outlined,
          ),
        );
      }
      return withSessionHeader(
        StateView.error(
          title: 'Не удалось загрузить профиль',
          body: state.failure?.message ?? 'Повторите попытку.',
          actionLabel: 'Повторить',
          onAction: () => controller.load(login),
        ),
      );
    }

    final owner = state.inferredOwner;
    final avatarUrl = owner?.avatarUrl ?? sessionUser?.avatarUrl;
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
          if (state.phase == LoadPhase.offlineWithCache)
            SliverToBoxAdapter(
              child: OfflineBanner(
                message: _offlineProfileMessage(
                  state.cachedAt,
                  publicOnly: sessionUser != null,
                ),
                onRetry: () => controller.load(login),
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
                    backgroundImage: appImageProvider(avatarUrl),
                    child: avatarUrl == null
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
                PostCard(post: state.items[index], onVote: null),
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

String _offlineProfileMessage(DateTime? cachedAt, {required bool publicOnly}) {
  final scope = publicOnly ? ' · только публичная выдача' : '';
  if (cachedAt == null) return 'Показаны сохранённые публикации профиля$scope';
  final local = cachedAt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return 'Показаны сохранённые публикации профиля · данные от '
      '$day.$month $hour:$minute$scope';
}

class _SessionProfileHeader extends StatelessWidget {
  const _SessionProfileHeader({required this.user});

  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.appColors.divider,
            backgroundImage: appImageProvider(user.avatarUrl),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '@${user.login}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
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
