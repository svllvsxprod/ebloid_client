import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class AppMediaImage extends StatelessWidget {
  const AppMediaImage({
    super.key,
    this.networkUrl,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  final Uri? networkUrl;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final url = networkUrl;
    if (url == null) {
      return _errorBuilder(context, StateError('No media'), null);
    }
    return Image.network(
      url.toString(),
      fit: fit,
      semanticLabel: semanticLabel,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null || wasSynchronouslyLoaded) return child;
        return ColoredBox(
          color: context.appColors.soft,
          child: const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Медиа загружается',
            ),
          ),
        );
      },
      errorBuilder: _errorBuilder,
    );
  }

  Widget _errorBuilder(BuildContext context, Object error, StackTrace? stack) {
    return ColoredBox(
      color: context.appColors.soft,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          semanticLabel: 'Не удалось загрузить медиа',
        ),
      ),
    );
  }
}

ImageProvider<Object>? appImageProvider(Uri? networkUrl) =>
    networkUrl == null ? null : NetworkImage(networkUrl.toString());
