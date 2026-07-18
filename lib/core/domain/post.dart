import 'content_state.dart';
import 'feed.dart';

const int reactionDelta = 1;

enum Reaction { none, upvote, downvote }

enum PostAvailability {
  available,
  deleted,
  unavailable,
  restricted,
  moderating,
}

enum MediaKind { image, video, audio, album }

enum CommentState { visible, deleted, hidden, pending }

extension ReactionScore on Reaction {
  int get scoreValue {
    switch (this) {
      case Reaction.none:
        return 0;
      case Reaction.upvote:
        return reactionDelta;
      case Reaction.downvote:
        return -reactionDelta;
    }
  }
}

int scoreAfterReaction({
  required int currentScore,
  required Reaction previous,
  required Reaction next,
}) {
  return currentScore - previous.scoreValue + next.scoreValue;
}

final class UserRef {
  const UserRef({required this.id, required this.displayName, this.avatarUrl});

  final String id;
  final String displayName;
  final Uri? avatarUrl;

  @override
  bool operator ==(Object other) {
    return other is UserRef &&
        other.id == id &&
        other.displayName == displayName &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode => Object.hash(id, displayName, avatarUrl);
}

final class MediaItem {
  const MediaItem({
    required this.id,
    required this.kind,
    required this.semanticLabel,
    this.duration,
    this.aspectRatio,
    this.previewUrl,
    this.contentUrl,
  }) : assert(kind != MediaKind.album, 'Album uses MediaAsset.album.');

  final String id;
  final MediaKind kind;
  final String semanticLabel;
  final Duration? duration;
  final double? aspectRatio;
  final Uri? previewUrl;
  final Uri? contentUrl;

  @override
  bool operator ==(Object other) {
    return other is MediaItem &&
        other.id == id &&
        other.kind == kind &&
        other.semanticLabel == semanticLabel &&
        other.duration == duration &&
        other.aspectRatio == aspectRatio &&
        other.previewUrl == previewUrl &&
        other.contentUrl == contentUrl;
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    semanticLabel,
    duration,
    aspectRatio,
    previewUrl,
    contentUrl,
  );
}

final class MediaAsset {
  const MediaAsset.single(this.item) : items = const [];

  const MediaAsset.album(this.items) : item = null;

  final MediaItem? item;
  final List<MediaItem> items;

  MediaKind get kind => item == null ? MediaKind.album : item!.kind;

  List<MediaItem> get flattened => item == null ? items : [item!];

  bool get isAlbum => item == null;

  @override
  bool operator ==(Object other) {
    return other is MediaAsset &&
        other.item == item &&
        _listEquals(other.items, items);
  }

  @override
  int get hashCode => Object.hash(item, Object.hashAll(items));
}

final class PostPermissions {
  const PostPermissions({
    this.canReact = false,
    this.canComment = false,
    this.canShare = true,
    this.canEdit = false,
    this.canDelete = false,
  });

  final bool canReact;
  final bool canComment;
  final bool canShare;
  final bool canEdit;
  final bool canDelete;
}

final class PostCounters {
  const PostCounters({
    required this.views,
    required this.score,
    required this.comments,
  });

  final int views;
  final int score;
  final int comments;

  PostCounters copyWith({int? views, int? score, int? comments}) {
    return PostCounters(
      views: views ?? this.views,
      score: score ?? this.score,
      comments: comments ?? this.comments,
    );
  }
}

final class PostSummary {
  const PostSummary({
    required this.id,
    required this.shortCode,
    required this.author,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.media,
    required this.counters,
    required this.availability,
    this.isStreamSafe,
    required this.userReaction,
    required this.permissions,
  });

  final String id;
  final String shortCode;
  final UserRef author;
  final DateTime createdAt;
  final String title;
  final String description;
  final MediaAsset media;
  final PostCounters counters;
  final PostAvailability availability;
  final bool? isStreamSafe;
  final Reaction userReaction;
  final PostPermissions permissions;

  FeedMediaType get feedType {
    switch (media.kind) {
      case MediaKind.image:
        return FeedMediaType.image;
      case MediaKind.video:
        return FeedMediaType.video;
      case MediaKind.audio:
        return FeedMediaType.audio;
      case MediaKind.album:
        return FeedMediaType.album;
    }
  }

  PostSummary copyWith({
    PostCounters? counters,
    Reaction? userReaction,
    PostAvailability? availability,
  }) {
    return PostSummary(
      id: id,
      shortCode: shortCode,
      author: author,
      createdAt: createdAt,
      title: title,
      description: description,
      media: media,
      counters: counters ?? this.counters,
      availability: availability ?? this.availability,
      isStreamSafe: isStreamSafe,
      userReaction: userReaction ?? this.userReaction,
      permissions: permissions,
    );
  }
}

final class PostDetail {
  const PostDetail({
    required this.summary,
    required this.comments,
    this.commentsFailure,
  });

  final PostSummary summary;
  final List<Comment> comments;
  final DomainFailure? commentsFailure;
}

final class CommentPermissions {
  const CommentPermissions({
    this.canReply = false,
    this.canReact = false,
    this.canEdit = false,
    this.canDelete = false,
  });

  final bool canReply;
  final bool canReact;
  final bool canEdit;
  final bool canDelete;
}

final class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.createdAt,
    required this.body,
    required this.score,
    required this.state,
    required this.userReaction,
    required this.permissions,
    this.editedAt,
    this.parentId,
    this.replies = const [],
  });

  final String id;
  final String postId;
  final String? parentId;
  final UserRef author;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String body;
  final int score;
  final CommentState state;
  final Reaction userReaction;
  final CommentPermissions permissions;
  final List<Comment> replies;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
