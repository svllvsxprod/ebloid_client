enum SearchResultKind { post, video, profile }

final class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.target,
    this.subtitle,
    this.thumbnailUrl,
  });

  final String id;
  final SearchResultKind kind;
  final String title;
  final String? subtitle;
  final Uri? thumbnailUrl;
  final String target;
}
