import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/domain/content_state.dart';
import '../../core/domain/search.dart';
import '../../core/platform/platform_adapters.dart';
import '../../core/widgets/widgets.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(
      text: ref.read(searchControllerProvider).query,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => ref.read(searchControllerProvider.notifier).search(value),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    return Scaffold(
      appBar: AppTopBar(
        title: 'Поиск',
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _queryController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                ref.read(searchControllerProvider.notifier).search(value);
              },
              decoration: InputDecoration(
                labelText: 'Публикации, видео и пользователи',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _queryController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Очистить поиск',
                        onPressed: () {
                          _debounce?.cancel();
                          _queryController.clear();
                          ref
                              .read(searchControllerProvider.notifier)
                              .search('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(child: _SearchBody(state: state)),
        ],
      ),
    );
  }
}

class _SearchBody extends ConsumerWidget {
  const _SearchBody({required this.state});

  final SearchControllerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!state.hasSearched) {
      return const StateView.empty(
        title: 'Найдите контент',
        body: 'Введите минимум два символа.',
        icon: Icons.manage_search_rounded,
      );
    }
    if (state.phase == LoadPhase.initialLoading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Поиск выполняется'),
      );
    }
    if (state.phase == LoadPhase.empty) {
      return const StateView.empty(
        title: 'Ничего не найдено',
        body: 'Попробуйте изменить запрос.',
        icon: Icons.search_off_rounded,
      );
    }
    if (state.results.isEmpty) {
      return StateView.error(
        title: 'Поиск недоступен',
        body: state.failure?.message ?? 'Повторите попытку.',
        actionLabel: 'Повторить',
        onAction: () =>
            ref.read(searchControllerProvider.notifier).search(state.query),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        for (final kind in SearchResultKind.values)
          if (state.results.any((item) => item.kind == kind)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Text(
                _kindLabel(kind),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.appColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final item in state.results.where((item) => item.kind == kind))
              _SearchResultTile(item: item),
          ],
      ],
    );
  }

  String _kindLabel(SearchResultKind kind) => switch (kind) {
    SearchResultKind.post => 'Публикации',
    SearchResultKind.video => 'Видео',
    SearchResultKind.profile => 'Пользователи',
  };
}

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      minTileHeight: AppSpacing.target,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      leading: _SearchThumbnail(item: item),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: item.subtitle == null ? null : Text(item.subtitle!),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _open(context, ref),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    try {
      switch (item.kind) {
        case SearchResultKind.profile:
          context.pushNamed(
            'public-profile',
            pathParameters: {'login': item.target},
          );
        case SearchResultKind.post:
          await ref
              .read(externalUrlAdapterProvider)
              .open(canonicalPostUri(item.target));
        case SearchResultKind.video:
          await ref
              .read(externalUrlAdapterProvider)
              .open(Uri.parse(item.target));
      }
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть результат.')),
      );
    }
  }
}

class _SearchThumbnail extends StatelessWidget {
  const _SearchThumbnail({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    final fallback = switch (item.kind) {
      SearchResultKind.post => Icons.insert_drive_file_outlined,
      SearchResultKind.video => Icons.smart_display_outlined,
      SearchResultKind.profile => Icons.person_outline_rounded,
    };
    final url = item.thumbnailUrl;
    return SizedBox.square(
      dimension: AppSpacing.target,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: url == null
            ? ColoredBox(
                color: context.appColors.soft,
                child: Icon(fallback, color: context.appColors.muted),
              )
            : Image.network(
                url.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: context.appColors.soft,
                  child: Icon(fallback, color: context.appColors.muted),
                ),
              ),
      ),
    );
  }
}
