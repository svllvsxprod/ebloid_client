import 'dart:math';

import 'package:characters/characters.dart';

import 'post.dart';

const int createPostTitleMaxGraphemes = 90;
const int createPostDescriptionMaxCodeUnits = 1000;
const int createPostMaxFiles = 10;
const int createPostMaxBytes = 200 * 1024 * 1024;

enum PostVisibility { public, unlisted }

enum UploadPhase {
  idle,
  validating,
  uploading,
  cancelling,
  cancelled,
  failed,
  retrying,
  processing,
  publishing,
  published,
}

enum LocalMediaAvailability { available, missing }

final class LocalMediaRef {
  const LocalMediaRef({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.localUri,
    this.sourceUri,
    this.sizeBytes,
    this.availability = LocalMediaAvailability.available,
  });

  final String id;
  final MediaKind kind;
  final String displayName;
  final Uri localUri;
  final Uri? sourceUri;
  final int? sizeBytes;
  final LocalMediaAvailability availability;

  LocalMediaRef copyWith({LocalMediaAvailability? availability}) {
    return LocalMediaRef(
      id: id,
      kind: kind,
      displayName: displayName,
      localUri: localUri,
      sourceUri: sourceUri,
      sizeBytes: sizeBytes,
      availability: availability ?? this.availability,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LocalMediaRef &&
        other.id == id &&
        other.kind == kind &&
        other.displayName == displayName &&
        other.localUri == localUri &&
        other.sourceUri == sourceUri &&
        other.sizeBytes == sizeBytes &&
        other.availability == availability;
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    displayName,
    localUri,
    sourceUri,
    sizeBytes,
    availability,
  );
}

final class CreatePostDraft {
  const CreatePostDraft({
    required this.id,
    required this.uploadId,
    required this.updatedAt,
    this.title = '',
    this.description = '',
    this.notForStream = false,
    this.allowComments = true,
    this.visibility = PostVisibility.unlisted,
    this.media = const [],
  });

  final String id;
  final String uploadId;
  final DateTime updatedAt;
  final String title;
  final String description;
  final bool notForStream;
  final bool allowComments;
  final PostVisibility visibility;
  final List<LocalMediaRef> media;

  int get titleGraphemeLength => title.characters.length;

  bool get isTitleValid => titleGraphemeLength <= createPostTitleMaxGraphemes;

  bool get isEmpty {
    return title.isEmpty &&
        description.isEmpty &&
        media.isEmpty &&
        !notForStream &&
        allowComments &&
        visibility == PostVisibility.unlisted;
  }

  CreatePostDraft copyWith({
    DateTime? updatedAt,
    String? title,
    String? description,
    bool? notForStream,
    bool? allowComments,
    PostVisibility? visibility,
    List<LocalMediaRef>? media,
  }) {
    return CreatePostDraft(
      id: id,
      uploadId: uploadId,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      notForStream: notForStream ?? this.notForStream,
      allowComments: allowComments ?? this.allowComments,
      visibility: visibility ?? this.visibility,
      media: media ?? this.media,
    );
  }
}

final class FileUploadProgress {
  const FileUploadProgress({
    required this.mediaId,
    required this.sentBytes,
    required this.totalBytes,
  });

  final String mediaId;
  final int sentBytes;
  final int totalBytes;

  double get fraction => totalBytes == 0 ? 0 : sentBytes / totalBytes;

  bool get isComplete => sentBytes >= totalBytes;
}

final class UploadProgress {
  const UploadProgress({
    required this.phase,
    this.files = const [],
    this.errorCode,
    this.errorMessage,
    this.publishedShortCode,
  });

  final UploadPhase phase;
  final List<FileUploadProgress> files;
  final String? errorCode;
  final String? errorMessage;
  final String? publishedShortCode;

  double get totalFraction {
    if (files.isEmpty) return 0;
    final sent = files.fold<int>(0, (sum, file) => sum + file.sentBytes);
    final total = files.fold<int>(0, (sum, file) => sum + file.totalBytes);
    return total == 0 ? 0 : sent / total;
  }
}

String generateUploadId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${value.substring(0, 8)}-'
      '${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-'
      '${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

final class PublishResult {
  const PublishResult({required this.shortCode});

  final String shortCode;
}
