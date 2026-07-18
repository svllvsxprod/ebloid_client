enum FeedMediaType { all, image, video, audio, album }

enum FeedSort { best, newest, views, score, comments }

enum FeedPeriod { today, week, month, year, allTime }

final class FeedQuery {
  const FeedQuery({
    this.type = FeedMediaType.all,
    this.sort = FeedSort.best,
    this.period = FeedPeriod.today,
    this.streamSafeOnly = false,
  });

  final FeedMediaType type;
  final FeedSort sort;
  final FeedPeriod period;
  final bool streamSafeOnly;

  FeedQuery copyWith({
    FeedMediaType? type,
    FeedSort? sort,
    FeedPeriod? period,
    bool? streamSafeOnly,
  }) {
    return FeedQuery(
      type: type ?? this.type,
      sort: sort ?? this.sort,
      period: period ?? this.period,
      streamSafeOnly: streamSafeOnly ?? this.streamSafeOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FeedQuery &&
        other.type == type &&
        other.sort == sort &&
        other.period == period &&
        other.streamSafeOnly == streamSafeOnly;
  }

  @override
  int get hashCode => Object.hash(type, sort, period, streamSafeOnly);

  @override
  String toString() {
    return 'FeedQuery(type: $type, sort: $sort, period: $period, '
        'streamSafeOnly: $streamSafeOnly)';
  }
}
