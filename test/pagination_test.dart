import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab/shared/pagination/paginated_state.dart';

void main() {
  group('PaginationState', () {
    test('default hasMore is true', () {
      const state = PaginationState();
      expect(state.hasMore, true);
      expect(state.cursor, null);
      expect(state.isLoadingMore, false);
    });

    test('copyWith updates fields', () {
      const state = PaginationState();
      final updated = state.copyWith(cursor: 'abc', hasMore: false, isLoadingMore: true);
      expect(updated.cursor, 'abc');
      expect(updated.hasMore, false);
      expect(updated.isLoadingMore, true);
    });

    test('copyWith preserves unchanged fields', () {
      const state = PaginationState(cursor: 'abc', hasMore: true, isLoadingMore: false);
      final updated = state.copyWith(isLoadingMore: true);
      expect(updated.cursor, 'abc');
      expect(updated.hasMore, true);
      expect(updated.isLoadingMore, true);
    });
  });
}
