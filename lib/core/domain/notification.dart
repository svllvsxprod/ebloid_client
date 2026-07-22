enum NotificationCategory { all, replies, ratings, videos, system }

extension NotificationCategoryCopy on NotificationCategory {
  String get label => switch (this) {
    NotificationCategory.all => 'Все',
    NotificationCategory.replies => 'Ответы',
    NotificationCategory.ratings => 'Оценки',
    NotificationCategory.videos => 'Видео',
    NotificationCategory.system => 'Система',
  };
}

enum NotificationKind {
  commentReply,
  postComment,
  commentPinned,
  postLike,
  videoApproved,
  videoRejected,
  videoViewed,
  adminBroadcast,
  system,
  unknown,
}

final class NotificationTarget {
  const NotificationTarget.app(this.appLocation) : externalUri = null;

  const NotificationTarget.external(this.externalUri) : appLocation = null;

  final String? appLocation;
  final Uri? externalUri;
}

final class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.scope,
    required this.kind,
    required this.title,
    required this.message,
    this.createdAt,
    required this.isRead,
    this.target,
  });

  final String id;
  final String scope;
  final NotificationKind kind;
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool isRead;
  final NotificationTarget? target;

  NotificationCategory get category => switch (kind) {
    NotificationKind.commentReply ||
    NotificationKind.postComment ||
    NotificationKind.commentPinned => NotificationCategory.replies,
    NotificationKind.postLike => NotificationCategory.ratings,
    NotificationKind.videoApproved ||
    NotificationKind.videoRejected ||
    NotificationKind.videoViewed => NotificationCategory.videos,
    NotificationKind.adminBroadcast ||
    NotificationKind.system ||
    NotificationKind.unknown => NotificationCategory.system,
  };

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      scope: scope,
      kind: kind,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      target: target,
    );
  }
}

final class NotificationInbox {
  const NotificationInbox({required this.items, required this.unreadCount});

  final List<NotificationItem> items;
  final int unreadCount;
}

final class NotificationPreferences {
  const NotificationPreferences({
    required this.notifyLikes,
    required this.notifyComments,
  });

  final bool notifyLikes;
  final bool notifyComments;
}
