import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/platform/platform_adapters.dart';
import '../../core/widgets/widgets.dart';
import 'support_destinations.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'Правила сервиса',
      introduction:
          'Справочная сводка опубликованных условий использования eblo.id. '
          'Она не заменяет полный юридический текст.',
      sections: [
        _LegalSection(
          title: 'Сервис и возраст',
          paragraphs: [
            'eblo.id заявлен как некоммерческая платформа пользовательского контента.',
            'Пользователь подтверждает возраст 18 лет или старше.',
          ],
        ),
        _LegalSection(
          title: 'Запрещённый контент',
          paragraphs: [
            'Сексуальный контент и материалы 18+ запрещены полностью, в том числе при блюре или отметке «Не для стрима».',
            'Запрещены незаконные материалы, травля и дискриминация, нарушения правил Twitch и авторских прав, вредоносные файлы, накрутка, вмешательство в работу сервиса, публикация чужих персональных данных и несогласованная реклама.',
          ],
        ),
        _LegalSection(
          title: 'Модерация',
          paragraphs: [
            'Администрация может изменять или удалять контент и ограничивать аккаунты при нарушении правил.',
            'Для жалобы или вопроса используйте раздел поддержки.',
          ],
        ),
      ],
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScreen(
      title: 'Конфиденциальность',
      introduction:
          'Справочная сводка опубликованной политики конфиденциальности eblo.id. '
          'Она не заменяет полный юридический текст.',
      sections: [
        _LegalSection(
          title: 'Обрабатываемые данные',
          paragraphs: [
            'Сервис заявляет обработку email, IP-адреса и user-agent для работы и безопасности.',
          ],
        ),
        _LegalSection(
          title: 'Удаление данных',
          paragraphs: [
            'Запрос на удаление данных направляется на support@eblo.id.',
            'Перед отправкой запроса уточните последствия для публикаций, комментариев, профиля и связанных данных.',
          ],
        ),
      ],
    );
  }
}

class _LegalScreen extends ConsumerWidget {
  const _LegalScreen({
    required this.title,
    required this.introduction,
    required this.sections,
  });

  final String title;
  final String introduction;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTopBar(
        title: title,
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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            legalRevisionLabel,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.appColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(introduction),
          const SizedBox(height: AppSpacing.lg),
          for (final section in sections) ...[
            Semantics(
              header: true,
              child: Text(
                section.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final paragraph in section.paragraphs) ...[
              Text(paragraph),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
          OutlinedButton.icon(
            onPressed: () async {
              try {
                if (legalSourceUri != Uri.https('eblo.id', '/')) {
                  throw StateError('Unexpected legal source');
                }
                await ref.read(externalUrlAdapterProvider).open(legalSourceUri);
              } on Object {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Не удалось открыть eblo.id.')),
                );
              }
            },
            icon: const Icon(Icons.open_in_new_rounded),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
            label: const Text('Открыть eblo.id'),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}
