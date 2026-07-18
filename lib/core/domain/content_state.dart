enum LoadPhase {
  initialLoading,
  refreshing,
  paginating,
  empty,
  offlineWithCache,
  offlineEmpty,
  recoverableError,
  fatalError,
  unauthorized,
  restricted,
  success,
}

final class DomainFailure {
  const DomainFailure({
    required this.code,
    required this.message,
    this.requestId,
    this.recoverable = true,
  });

  final String code;
  final String message;
  final String? requestId;
  final bool recoverable;

  @override
  bool operator ==(Object other) {
    return other is DomainFailure &&
        other.code == code &&
        other.message == message &&
        other.requestId == requestId &&
        other.recoverable == recoverable;
  }

  @override
  int get hashCode => Object.hash(code, message, requestId, recoverable);
}

enum PageCursorKind { offset, cursor, page }

final class PageCursor {
  const PageCursor(this.value, {this.kind = PageCursorKind.offset});

  final String value;
  final PageCursorKind kind;

  @override
  bool operator ==(Object other) =>
      other is PageCursor && other.value == value && other.kind == kind;

  @override
  int get hashCode => Object.hash(value, kind);
}

final class PageResult<T> {
  const PageResult({required this.items, this.nextCursor});

  final List<T> items;
  final PageCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}
