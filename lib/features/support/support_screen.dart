import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/platform/platform_adapters.dart';
import '../../core/widgets/widgets.dart';
import 'support_destinations.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  late final Future<AppBuildInfo> _appInfo;

  @override
  void initState() {
    super.initState();
    _appInfo = ref.read(appInfoAdapterProvider).load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Поддержка',
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Нашли ошибку или нужна помощь?',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Выберите удобный способ связи. Приложение ничего не отправляет '
            'без вашего явного действия.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.appColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SupportAction(
            icon: Icons.campaign_outlined,
            title: 'Канал в Telegram',
            subtitle: 'Новости и обновления eblo.id',
            onTap: () => _openExternal(supportTelegramChannelUri),
          ),
          _SupportAction(
            icon: Icons.support_agent_rounded,
            title: 'Чат с администраторами',
            subtitle: 'Задать вопрос или сообщить о проблеме напрямую',
            onTap: () => _openExternal(supportAdministratorChatUri),
          ),
          _SupportAction(
            icon: Icons.email_outlined,
            title: supportEmailAddress,
            subtitle: 'Открыть новое письмо без автоматической отправки',
            onTap: () => _composeEmail('Поддержка eblo.id'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              'Данные и правила',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SupportAction(
            icon: Icons.person_remove_outlined,
            title: 'Запросить удаление данных',
            subtitle:
                'Открыть письмо в поддержку. Последствия удаления уточняются '
                'до подтверждения запроса.',
            onTap: _confirmDataDeletionRequest,
          ),
          _SupportAction(
            icon: Icons.gavel_outlined,
            title: 'Правила сервиса',
            subtitle: legalRevisionLabel,
            onTap: () => context.pushNamed('rules'),
          ),
          _SupportAction(
            icon: Icons.privacy_tip_outlined,
            title: 'Политика конфиденциальности',
            subtitle: legalRevisionLabel,
            onTap: () => context.pushNamed('privacy'),
          ),
          const SizedBox(height: AppSpacing.lg),
          FutureBuilder<AppBuildInfo>(
            future: _appInfo,
            builder: (context, snapshot) {
              final info = snapshot.data;
              return _SupportAction(
                icon: Icons.info_outline_rounded,
                title: info?.label ?? 'Версия приложения',
                subtitle: info == null
                    ? 'Информация о сборке недоступна'
                    : 'Скопировать для обращения в поддержку',
                onTap: info == null ? null : () => _copyBuildInfo(info),
              );
            },
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/feed');
    }
  }

  Future<void> _openExternal(Uri uri) async {
    if (!isAllowedSupportDestination(uri)) {
      _showMessage('Ссылка поддержки недоступна.');
      return;
    }
    try {
      await ref.read(externalUrlAdapterProvider).open(uri);
    } on Object {
      if (!mounted) return;
      _showMessage('Не удалось открыть ссылку.');
    }
  }

  Future<void> _confirmDataDeletionRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Запрос удаления данных'),
        content: const Text(
          'Поддержка должна уточнить последствия для публикаций, комментариев, '
          'загрузок, профиля, уведомлений, а также правила хранения или '
          'анонимизации. Письмо не будет отправлено автоматически.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Продолжить к письму'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _composeEmail('Запрос на удаление данных eblo.id');
    }
  }

  Future<void> _composeEmail(String subject) async {
    try {
      await ref.read(supportEmailAdapterProvider).compose(subject: subject);
    } on Object {
      try {
        await ref.read(clipboardAdapterProvider).copy(supportEmailAddress);
      } on Object {
        if (!mounted) return;
        _showMessage(
          'Почтовое приложение недоступно. Адрес: $supportEmailAddress',
        );
        return;
      }
      if (!mounted) return;
      _showMessage('Почтовое приложение недоступно. Адрес скопирован.');
    }
  }

  Future<void> _copyBuildInfo(AppBuildInfo info) async {
    try {
      await ref.read(clipboardAdapterProvider).copy('eblo.id ${info.label}');
      if (!mounted) return;
      _showMessage('Версия и номер сборки скопированы.');
    } on Object {
      if (!mounted) return;
      _showMessage('Не удалось скопировать информацию о сборке.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap != null,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: ListTile(
        minTileHeight: 64,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        leading: SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.appColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: context.appColors.accent),
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
