final class VideoCategory {
  const VideoCategory({
    required this.id,
    required this.title,
    required this.status,
    required this.sortOrder,
    required this.videosCount,
  });

  final String id;
  final String title;
  final String status;
  final int sortOrder;
  final int videosCount;
}

final class VideoAuthorRef {
  const VideoAuthorRef({required this.displayName});

  final String displayName;
}

final class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.status,
    required this.categories,
    required this.views,
    required this.likes,
    required this.votes,
    required this.hasVoted,
    this.url,
    this.youtubeId,
    this.thumbnailUrl,
    this.previewUrl,
    this.author,
    this.channelTitle,
    this.comment,
    this.duration,
    this.createdAt,
    this.publishedAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final Uri? url;
  final String? youtubeId;
  final Uri? thumbnailUrl;
  final Uri? previewUrl;
  final String status;
  final List<VideoCategory> categories;
  final VideoAuthorRef? author;
  final String? channelTitle;
  final String? comment;
  final int views;
  final int likes;
  final int votes;
  final bool hasVoted;
  final Duration? duration;
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
}
