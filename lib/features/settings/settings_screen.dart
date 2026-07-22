import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/domain/content_state.dart';
import '../../core/widgets/widgets.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    return Scaffold(
      appBar: AppTopBar(
        title: 'Настройки',
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/feed');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: switch (state.phase) {
        LoadPhase.initialLoading => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Настройки загружаются',
          ),
        ),
        LoadPhase.unauthorized => StateView.unauthorized(
          title: 'Войдите через Twitch',
          body: 'Для синхронизации настроек уведомлений требуется вход.',
          actionLabel: 'Войти',
          onAction: () async {
            await context.pushNamed('auth-twitch');
            await notifier.load();
          },
        ),
        LoadPhase.recoverableError || LoadPhase.offlineEmpty => StateView.error(
          title: 'Не удалось загрузить настройки',
          body: state.failure?.message ?? 'Повторите попытку.',
          actionLabel: 'Повторить',
          onAction: notifier.load,
        ),
        LoadPhase.fatalError => StateView(
          variant: StateViewVariant.fatalError,
          title: 'Настройки недоступны',
          body: state.failure?.message ?? 'Безопасно вернитесь позже.',
          icon: Icons.settings_outlined,
        ),
        _ => _SettingsBody(state: state),
      },
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.state});

  final SettingsControllerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsControllerProvider.notifier);
    final preferences = state.preferences!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Уведомления',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Настройки лайков и комментариев синхронизируются с eblo.id. '
          'Звук хранится только на этом устройстве.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.appColors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsSwitch(
          title: 'Лайки и оценки',
          subtitle: 'Сообщать о новых реакциях на публикации.',
          value: preferences.notifyLikes,
          enabled: !state.saving,
          onChanged: notifier.setNotifyLikes,
        ),
        _SettingsSwitch(
          title: 'Комментарии и ответы',
          subtitle: 'Сообщать о комментариях к публикациям и новых ответах.',
          value: preferences.notifyComments,
          enabled: !state.saving,
          onChanged: notifier.setNotifyComments,
        ),
        _SettingsSwitch(
          title: 'Звук уведомлений',
          subtitle: 'Локальная настройка только для этого устройства.',
          value: state.soundEnabled,
          enabled: !state.saving,
          onChanged: notifier.setSoundEnabled,
        ),
        if (state.saving) ...[
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(
            semanticsLabel: 'Настройки сохраняются',
          ),
        ],
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              state.failure!.message,
              style: TextStyle(color: context.appColors.danger),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            'Помощь и документы',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _SettingsNavigationTile(
          icon: Icons.support_agent_rounded,
          label: 'Поддержка',
          onTap: () => context.pushNamed('support'),
        ),
        _SettingsNavigationTile(
          icon: Icons.gavel_outlined,
          label: 'Правила сервиса',
          onTap: () => context.pushNamed('rules'),
        ),
        _SettingsNavigationTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Политика конфиденциальности',
          onTap: () => context.pushNamed('privacy'),
        ),
      ],
    );
  }
}

class _SettingsNavigationTile extends StatelessWidget {
  const _SettingsNavigationTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: ListTile(
        minTileHeight: 64,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      toggled: value,
      label: '$title. $subtitle',
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
