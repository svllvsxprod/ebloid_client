import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/domain/create_post.dart';
import '../../core/domain/post.dart';
import '../../core/platform/platform_adapters.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_controller.dart';
import 'create_post_controller.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Timer? _titleDebounce;
  Timer? _descriptionDebounce;
  String? _storageError;
  var _restoring = true;
  var _publishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleDebounce?.cancel();
    _descriptionDebounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _flushDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(createFlowAvailableProvider)) {
      return Scaffold(
        appBar: AppTopBar(
          title: 'Новая публикация',
          leading: IconButton(
            tooltip: 'Вернуться в ленту',
            onPressed: () => context.goNamed('feed'),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: StateView(
          variant: StateViewVariant.fatalError,
          title: 'Публикация пока недоступна',
          body:
              'Для реальной загрузки нужны безопасный Twitch-вход и '
              'утверждённые контракты UPLOAD-01 и PUBLISH-01.',
          actionLabel: 'Вернуться в ленту',
          onAction: () => context.goNamed('feed'),
          icon: Icons.cloud_upload_outlined,
        ),
      );
    }
    final auth = ref.watch(authControllerProvider);
    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Проверка входа'),
        ),
      );
    }
    if (auth.value != true) {
      return Scaffold(
        appBar: AppTopBar(
          title: 'Новая публикация',
          leading: IconButton(
            tooltip: 'Вернуться в ленту',
            onPressed: () => context.goNamed('feed'),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: StateView.unauthorized(
          title: 'Войдите для публикации',
          body: 'Черновик сохранится, а после входа можно продолжить.',
          actionLabel: 'Войти через Twitch',
          onAction: () => context.pushNamed('auth-twitch'),
        ),
      );
    }
    final state = ref.watch(createPostControllerProvider);
    final draft = state.draft;
    final publishAvailable = ref.watch(publishAvailableProvider);
    return Scaffold(
      appBar: AppTopBar(
        title: 'Новая публикация',
        leading: IconButton(
          tooltip: 'Закрыть редактор',
          onPressed: _close,
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _restoring
            ? const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Восстановление черновика',
                ),
              )
            : _storageError != null
            ? StateView(
                variant: StateViewVariant.fatalError,
                title: 'Черновик недоступен',
                body: _storageError!,
                actionLabel: 'Повторить',
                onAction: _restore,
                icon: Icons.lock_outline_rounded,
              )
            : state.upload.phase == UploadPhase.published
            ? StateView(
                variant: StateViewVariant.success,
                title: 'Публикация создана',
                body: 'Код: ${state.upload.publishedShortCode}.',
                actionLabel: 'Открыть публикацию',
                onAction: () => context.goNamed(
                  'post',
                  pathParameters: {
                    'shortCode': state.upload.publishedShortCode!,
                  },
                ),
                icon: Icons.check_circle_outline_rounded,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  _MediaPicker(
                    media: draft.media,
                    enabled: !_publishing,
                    onAdd: _pickMedia,
                    onRemove: (id) => ref
                        .read(createPostControllerProvider.notifier)
                        .removeMedia(id),
                    onReorder: ref
                        .read(createPostControllerProvider.notifier)
                        .reorderMedia,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('create-title'),
                    controller: _titleController,
                    enabled: !_publishing,
                    maxLength: createPostTitleMaxGraphemes + 20,
                    onChanged: _onTitleChanged,
                    decoration: InputDecoration(
                      labelText: 'Заголовок',
                      hintText: 'О чём публикация?',
                      errorText: draft.isTitleValid
                          ? null
                          : 'Не больше $createPostTitleMaxGraphemes символов',
                      counterText:
                          '${_titleController.text.characters.length}/'
                          '$createPostTitleMaxGraphemes',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    key: const Key('create-description'),
                    controller: _descriptionController,
                    enabled: !_publishing,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: createPostDescriptionMaxCodeUnits,
                    onChanged: _onDescriptionChanged,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      hintText: 'Добавьте детали или ссылку',
                      helperText: 'Необязательно',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _VisibilityControl(
                    value: draft.visibility,
                    enabled: !_publishing,
                    onChanged: ref
                        .read(createPostControllerProvider.notifier)
                        .setVisibility,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DraftSwitch(
                    title: 'Не для стрима',
                    description:
                        'Пометка пригодности для стрима. Она не разрешает 18+ контент.',
                    value: draft.notForStream,
                    enabled: !_publishing,
                    onChanged: ref
                        .read(createPostControllerProvider.notifier)
                        .setNotForStream,
                  ),
                  _DraftSwitch(
                    title: 'Разрешить комментарии',
                    description:
                        'Текущий сервер всегда создаёт публикацию с комментариями.',
                    value: draft.allowComments,
                    enabled: false,
                    onChanged: ref
                        .read(createPostControllerProvider.notifier)
                        .setAllowComments,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.upload.phase != UploadPhase.idle)
                    _UploadPanel(
                      progress: state.upload,
                      onCancel: ref
                          .read(createPostControllerProvider.notifier)
                          .cancelUpload,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    key: const Key('publish-post'),
                    onPressed: _publishing || !publishAvailable
                        ? null
                        : _publish,
                    icon: const Icon(Icons.publish_rounded),
                    label: Text(
                      !publishAvailable
                          ? 'Публикация недоступна'
                          : state.upload.phase == UploadPhase.failed
                          ? 'Повторить публикацию'
                          : 'Опубликовать',
                    ),
                  ),
                  if (!publishAvailable) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Медиа и черновик сохраняются локально. Отправка появится '
                      'после подтверждения серверного контракта.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Черновик сохраняется в защищённом локальном хранилище.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _restore() async {
    if (!ref.read(createFlowAvailableProvider)) {
      if (mounted) setState(() => _restoring = false);
      return;
    }
    setState(() {
      _restoring = true;
      _storageError = null;
    });
    try {
      await ref.read(createPostControllerProvider.notifier).restore();
      final controller = ref.read(createPostControllerProvider.notifier);
      var draft = ref.read(createPostControllerProvider).draft;
      if (!draft.allowComments) {
        await controller.setAllowComments(true);
        draft = ref.read(createPostControllerProvider).draft;
      }
      if (draft.media.isNotEmpty) {
        final picker = ref.read(mediaPickerAdapterProvider);
        final media = await Future.wait(
          draft.media.map(picker.refreshAvailability),
        );
        await controller.replaceMedia(media);
        draft = ref.read(createPostControllerProvider).draft;
      }
      _titleController.text = draft.title;
      _descriptionController.text = draft.description;
    } on Object {
      _storageError =
          'Защищённое хранилище не отвечает. Небезопасный fallback запрещён.';
    }
    if (mounted) setState(() => _restoring = false);
  }

  void _onTitleChanged(String value) {
    setState(() {});
    _titleDebounce?.cancel();
    _titleDebounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(createPostControllerProvider.notifier).updateTitle(value);
    });
  }

  void _onDescriptionChanged(String value) {
    _descriptionDebounce?.cancel();
    _descriptionDebounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(createPostControllerProvider.notifier).updateDescription(value);
    });
  }

  Future<void> _flushDraft() async {
    _titleDebounce?.cancel();
    _descriptionDebounce?.cancel();
    final controller = ref.read(createPostControllerProvider.notifier);
    await controller.updateTitle(_titleController.text);
    await controller.updateDescription(_descriptionController.text);
  }

  Future<void> _pickMedia() async {
    try {
      final media = await ref.read(mediaPickerAdapterProvider).pickMedia();
      if (media.isEmpty) return;
      final existing = ref
          .read(createPostControllerProvider)
          .draft
          .media
          .length;
      if (existing + media.length > createPostMaxFiles) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Можно выбрать не больше 10 файлов.')),
        );
        return;
      }
      await ref.read(createPostControllerProvider.notifier).addMediaAll(media);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть выбранные файлы.')),
      );
    }
  }

  Future<void> _publish() async {
    await _flushDraft();
    if (!mounted) return;
    final draft = ref.read(createPostControllerProvider).draft;
    final titleLength = draft.title.trim().characters.length;
    if (titleLength == 0 || !draft.isTitleValid || draft.media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте медиа и корректный заголовок.')),
      );
      return;
    }
    setState(() => _publishing = true);
    await for (final progress
        in ref.read(createPostControllerProvider.notifier).publish()) {
      if (!mounted) return;
      if (progress.phase == UploadPhase.failed ||
          progress.phase == UploadPhase.cancelled ||
          progress.phase == UploadPhase.published) {
        setState(() => _publishing = false);
      }
    }
  }

  Future<void> _close() async {
    await _flushDraft();
    if (!mounted) return;
    final draft = ref.read(createPostControllerProvider).draft;
    if (!draft.isEmpty) {
      final action = await showDialog<_CloseAction>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Закрыть редактор?'),
          content: const Text(
            'Черновик можно сохранить для продолжения или удалить.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _CloseAction.cancel),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _CloseAction.discard),
              child: const Text('Удалить'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _CloseAction.keep),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      );
      if (action == _CloseAction.cancel || action == null) return;
      if (action == _CloseAction.discard) {
        await ref.read(createPostControllerProvider.notifier).discard();
      }
    }
    if (mounted) context.pop();
  }
}

enum _CloseAction { cancel, discard, keep }

class _MediaPicker extends StatelessWidget {
  const _MediaPicker({
    required this.media,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  final List<LocalMediaRef> media;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Добавить фото, видео, аудио или альбом',
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: enabled ? onAdd : null,
            child: CustomPaint(
              painter: _DashedDropzonePainter(
                color: context.appColors.muted,
                radius: AppRadius.lg,
              ),
              child: Container(
                constraints: const BoxConstraints(minHeight: 205),
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 36,
                      color: context.appColors.fg,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Добавить медиа',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Фото, видео, аудио или целый альбом',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (media.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: media.length,
            onReorderItem: enabled ? onReorder : (_, _) {},
            itemBuilder: (context, index) {
              final item = media[index];
              return ListTile(
                key: ValueKey(item.id),
                contentPadding: EdgeInsets.zero,
                leading: SizedBox.square(
                  dimension: AppSpacing.target,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: _LocalMediaThumbnail(media: item),
                  ),
                ),
                title: Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.availability == LocalMediaAvailability.missing
                      ? '${_mediaLabel(item.kind)} · файл недоступен'
                      : _mediaLabel(item.kind),
                  style: item.availability == LocalMediaAvailability.missing
                      ? TextStyle(color: Theme.of(context).colorScheme.error)
                      : null,
                ),
                trailing: IconButton(
                  tooltip: 'Удалить ${item.displayName}',
                  onPressed: enabled ? () => onRemove(item.id) : null,
                  icon: const Icon(Icons.close_rounded),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  String _mediaLabel(MediaKind kind) => switch (kind) {
    MediaKind.image => 'Изображение',
    MediaKind.video => 'Видео',
    MediaKind.audio => 'Аудио',
    MediaKind.album => 'Альбом',
  };
}

class _LocalMediaThumbnail extends StatelessWidget {
  const _LocalMediaThumbnail({required this.media});

  final LocalMediaRef media;

  @override
  Widget build(BuildContext context) {
    if (media.availability == LocalMediaAvailability.missing) {
      return _fallback(context, Icons.broken_image_outlined, 'Файл недоступен');
    }
    if (media.kind != MediaKind.image || media.localUri.scheme != 'file') {
      return _fallback(
        context,
        switch (media.kind) {
          MediaKind.video => Icons.videocam_outlined,
          MediaKind.audio => Icons.graphic_eq_rounded,
          MediaKind.image => Icons.image_outlined,
          MediaKind.album => Icons.collections_outlined,
        },
        switch (media.kind) {
          MediaKind.video => 'Видео',
          MediaKind.audio => 'Аудио',
          MediaKind.image => 'Изображение',
          MediaKind.album => 'Альбом',
        },
      );
    }
    return Image.file(
      File.fromUri(media.localUri),
      width: AppSpacing.target,
      height: AppSpacing.target,
      fit: BoxFit.cover,
      semanticLabel: media.displayName,
      errorBuilder: (context, error, stackTrace) =>
          _fallback(context, Icons.broken_image_outlined, 'Файл недоступен'),
    );
  }

  Widget _fallback(BuildContext context, IconData icon, String label) {
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: ColoredBox(
          color: context.appColors.divider,
          child: Icon(icon, color: context.appColors.muted),
        ),
      ),
    );
  }
}

class _DashedDropzonePainter extends CustomPainter {
  const _DashedDropzonePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect.deflate(.5));
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 7.0;
    const gap = 5.0;
    var distance = 0.0;
    while (distance < metric.length) {
      final next = distance + dash;
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedDropzonePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _VisibilityControl extends StatelessWidget {
  const _VisibilityControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final PostVisibility value;
  final bool enabled;
  final ValueChanged<PostVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Видимость публикации',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Видимость',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PostVisibility>(
              segments: const [
                ButtonSegment(
                  value: PostVisibility.unlisted,
                  label: Text('По ссылке'),
                  icon: Icon(Icons.link_rounded),
                ),
                ButtonSegment(
                  value: PostVisibility.public,
                  label: Text('В ленте'),
                  icon: Icon(Icons.public_rounded),
                ),
              ],
              selected: {value},
              onSelectionChanged: enabled
                  ? (selection) => onChanged(selection.single)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftSwitch extends StatelessWidget {
  const _DraftSwitch({
    required this.title,
    required this.description,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: '$title. $description',
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(description),
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({required this.progress, required this.onCancel});

  final UploadProgress progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final canCancel = progress.phase == UploadPhase.uploading;
    return Semantics(
      liveRegion: true,
      label:
          '${_phaseLabel(progress.phase)}. '
          '${(progress.totalFraction * 100).round()} процентов',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          border: Border.all(color: context.appColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _phaseLabel(progress.phase),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (canCancel)
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Отмена'),
                    ),
                ],
              ),
              LinearProgressIndicator(
                value:
                    progress.phase == UploadPhase.validating ||
                        progress.phase == UploadPhase.processing ||
                        progress.phase == UploadPhase.publishing
                    ? null
                    : progress.totalFraction,
              ),
              for (final file in progress.files) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${file.mediaId}: ${(file.fraction * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (progress.errorCode != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  progress.errorMessage ?? 'Код ошибки: ${progress.errorCode}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _phaseLabel(UploadPhase phase) => switch (phase) {
    UploadPhase.idle => 'Готово к публикации',
    UploadPhase.validating => 'Проверка файлов',
    UploadPhase.uploading => 'Загрузка файлов',
    UploadPhase.cancelling => 'Отмена загрузки',
    UploadPhase.cancelled => 'Загрузка отменена',
    UploadPhase.failed => 'Ошибка загрузки',
    UploadPhase.retrying => 'Повторная загрузка',
    UploadPhase.processing => 'Обработка на сервере',
    UploadPhase.publishing => 'Публикация',
    UploadPhase.published => 'Опубликовано',
  };
}
