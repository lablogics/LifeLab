/// Mixin for paginated state notifiers with cursor-based pagination.
/// Provides loadMore, hasMore, and cursor tracking.
mixin PaginatedMixin<T> {
  List<T> get _items;
  bool get _hasMore;
  String? get _cursor;
  bool get _isLoadingMore;

  /// Override to fetch next page. Return (items, nextCursor).
  Future<({List<T> items, String? nextCursor})> fetchPage(String? cursor);

  /// Call to load the next page of items.
  Future<void> loadMore(void Function(List<T> items, bool hasMore, String? cursor, bool loadingMore) update) async {
    if (_isLoadingMore || !_hasMore) return;
    update(_items, true, _cursor, true);
    try {
      final result = await fetchPage(_cursor);
      final allItems = [..._items, ...result.items];
      update(allItems, result.nextCursor != null, result.nextCursor, false);
    } catch (_) {
      update(_items, _hasMore, _cursor, false);
    }
  }
}

/// Simple pagination state helper.
class PaginationState {
  final String? cursor;
  final bool hasMore;
  final bool isLoadingMore;
  const PaginationState({this.cursor, this.hasMore = true, this.isLoadingMore = false});
  PaginationState copyWith({String? cursor, bool? hasMore, bool? isLoadingMore}) =>
    PaginationState(cursor: cursor ?? this.cursor, hasMore: hasMore ?? this.hasMore, isLoadingMore: isLoadingMore ?? this.isLoadingMore);
}
