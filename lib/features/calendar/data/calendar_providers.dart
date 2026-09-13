import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String type; // 'note' or 'todo'
  final String? dueDate;
  final int? updatedAt;
  final bool completed;

  const CalendarEvent({
    required this.id, required this.title, required this.type,
    this.dueDate, this.updatedAt, this.completed = false,
  });

  factory CalendarEvent.fromNoteJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      type: 'note',
      updatedAt: json['updatedAt'] as int?,
    );
  }

  factory CalendarEvent.fromTodoJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      type: 'todo',
      dueDate: json['dueDate'] as String?,
      completed: json['completed'] == true || json['completed'] == 1,
    );
  }

  DateTime? get date {
    if (dueDate != null) return DateTime.tryParse(dueDate!);
    if (updatedAt != null) return DateTime.fromMillisecondsSinceEpoch(updatedAt!);
    return null;
  }
}

class CalendarState {
  final Map<int, List<CalendarEvent>> eventsByDay;
  final bool isLoading;
  final String? error;
  final DateTime currentMonth;

  const CalendarState({
    this.eventsByDay = const {},
    this.isLoading = false,
    this.error,
    required this.currentMonth,
  });

  CalendarState copyWith({
    Map<int, List<CalendarEvent>>? eventsByDay,
    bool? isLoading,
    String? error,
    DateTime? currentMonth,
  }) {
    return CalendarState(
      eventsByDay: eventsByDay ?? this.eventsByDay,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentMonth: currentMonth ?? this.currentMonth,
    );
  }
}

class CalendarNotifier extends StateNotifier<CalendarState> {
  final ApiClient _api;
  CalendarNotifier(this._api) : super(CalendarState(currentMonth: DateTime.now())) {
    loadMonth(DateTime.now());
  }

  String _formatMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  Future<void> loadMonth(DateTime month) async {
    state = state.copyWith(currentMonth: month, isLoading: true);
    try {
      final r = await _api.dio.dio.get(
        Endpoints.calendar,
        queryParameters: {'month': _formatMonth(month)},
      );
      final data = r.data as Map<String, dynamic>;
      final notes = (data['notes'] as List?)?.map((e) => CalendarEvent.fromNoteJson(e as Map<String, dynamic>)).toList() ?? [];
      final todos = (data['todos'] as List?)?.map((e) => CalendarEvent.fromTodoJson(e as Map<String, dynamic>)).toList() ?? [];

      final byDay = <int, List<CalendarEvent>>{};
      for (final event in [...notes, ...todos]) {
        final day = event.date?.day;
        if (day != null) {
          byDay.putIfAbsent(day, () => []).add(event);
        }
      }
      state = state.copyWith(eventsByDay: byDay, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void previousMonth() {
    final prev = DateTime(state.currentMonth.year, state.currentMonth.month - 1);
    loadMonth(prev);
  }

  void nextMonth() {
    final next = DateTime(state.currentMonth.year, state.currentMonth.month + 1);
    loadMonth(next);
  }
}

final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(ref.watch(apiClientProvider));
});
