import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'export') _exportCalendar(context, ref, state);
              if (v == 'ics_export') _exportICS(context, ref, state);
              if (v == 'ics_import') _importICS(context, ref);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'export', child: Text('Export JSON')),
              const PopupMenuItem(value: 'ics_export', child: Text('Export ICS')),
              const PopupMenuItem(value: 'ics_import', child: Text('Import ICS')),
            ],
          ),
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
                            ? () => _showDayEvents(context, day, events, ref)
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

  void _showDayEvents(BuildContext context, int day, List<CalendarEvent> events, WidgetRef ref) {
    final state = ref.read(calendarProvider);
    final year = state.currentMonth.year;
    final month = state.currentMonth.month;
    final dateStr = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final notes = events.where((e) => e.type == 'note').toList();
    final todos = events.where((e) => e.type == 'todo').toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: Text('Day $day', style: Theme.of(ctx).textTheme.titleLarge)),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Daily Note'),
                  onPressed: () { Navigator.pop(ctx); _createDailyNote(context, ref, dateStr); },
                ),
              ]),
            ),
            if (notes.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 4), child: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ...notes.map((e) => ListTile(
                leading: const Icon(Icons.note, color: Colors.blue, size: 20),
                title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: const Text('Note'),
                onTap: () { Navigator.pop(ctx); context.push('/notes/${e.id}'); },
              )),
            ],
            if (todos.isNotEmpty) ...[
              const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('Todos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ...todos.map((e) => ListTile(
                leading: Icon(e.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: e.completed ? Colors.green : Colors.orange, size: 20),
                title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(decoration: e.completed ? TextDecoration.lineThrough : null)),
                subtitle: Text('Todo${e.completed ? " (done)" : ""}'),
              )),
            ],
            if (events.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No events'))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _createDailyNote(BuildContext context, WidgetRef ref, String dateStr) async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.post(Endpoints.notes, data: {
        'title': 'Daily Note - $dateStr',
        'contentJson': '{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Daily note for $dateStr"}]}]}',
      });
      final noteId = r.data['id'] as String?;
      if (noteId != null && context.mounted) {
        context.push('/notes/$noteId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create daily note: $e')));
      }
    }
  }

  void _exportCalendar(BuildContext context, WidgetRef ref, CalendarState state) async {
    try {
      final api = ref.read(apiClientProvider);
      final month = '${state.currentMonth.year.toString().padLeft(4, '0')}-${state.currentMonth.month.toString().padLeft(2, '0')}';
      final r = await api.dio.dio.get(Endpoints.calendar, queryParameters: {'month': month});
      final data = r.data;
      if (context.mounted) {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: Text('Export: ${_monthNames[state.currentMonth.month - 1]} ${state.currentMonth.year}'),
          content: SelectableText(
            data.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _exportICS(BuildContext context, WidgetRef ref, CalendarState state) async {
    try {
      final api = ref.read(apiClientProvider);
      final month = '${state.currentMonth.year.toString().padLeft(4, '0')}-${state.currentMonth.month.toString().padLeft(2, '0')}';
      final r = await api.dio.dio.get(Endpoints.calendar, queryParameters: {'month': month, 'format': 'ics'});
      final icsData = r.data is String ? r.data as String : r.data.toString();
      if (context.mounted) {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('ICS Export'),
          content: SelectableText(icsData, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ICS export failed: $e')));
      }
    }
  }

  void _importICS(BuildContext context, WidgetRef ref) async {
    try {
      final api = ref.read(apiClientProvider);
      // Show dialog explaining ICS import
      if (context.mounted) {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Import ICS'),
          content: const Text('To import an ICS file, use the web app or send the file to your server\'s calendar import endpoint. Mobile ICS file picking will be available in a future update.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}
