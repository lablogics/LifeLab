import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/calendar_providers.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calendarProvider);
    final theme = Theme.of(context);
    final notifier = ref.read(calendarProvider.notifier);

    final year = state.currentMonth.year;
    final month = state.currentMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday=1 .. Sunday=7
    final startWeekday = firstDay.weekday;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_monthNames[month - 1]} $year'),
        leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: notifier.previousMonth),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: notifier.nextMonth),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Day headers
                Row(
                  children: _dayNames.map((d) => Expanded(
                    child: Center(
                      child: Text(d, style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.outline, fontWeight: FontWeight.w600,
                      )),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                // Calendar grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                    ),
                    itemCount: 42, // 6 rows x 7 cols
                    itemBuilder: (context, index) {
                      final dayOffset = index - (startWeekday - 1);
                      if (dayOffset < 0 || dayOffset >= daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      final day = dayOffset + 1;
                      final events = state.eventsByDay[day] ?? [];
                      final isToday = DateTime.now().year == year &&
                          DateTime.now().month == month &&
                          DateTime.now().day == day;

                      return InkWell(
                        onTap: events.isNotEmpty
                            ? () => _showDayEvents(context, day, events)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isToday
                                ? theme.colorScheme.primaryContainer
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isToday ? FontWeight.bold : null,
                                  color: isToday ? theme.colorScheme.primary : null,
                                ),
                              ),
                              if (events.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: events.take(3).map((e) => Container(
                                    width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: e.type == 'todo'
                                          ? (e.completed ? Colors.green : Colors.orange)
                                          : theme.colorScheme.primary,
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showDayEvents(BuildContext context, int day, List<CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Day $day', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            ...events.map((e) => ListTile(
              leading: Icon(
                e.type == 'todo' ? Icons.check_circle : Icons.note,
                color: e.type == 'todo'
                    ? (e.completed ? Colors.green : Colors.orange)
                    : Colors.blue,
              ),
              title: Text(e.title),
              subtitle: Text(e.type == 'todo' ? 'Todo${e.completed ? " (done)" : ""}' : 'Note'),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
