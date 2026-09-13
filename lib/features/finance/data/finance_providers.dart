import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinanceEntry {
  final String id;
  final String description;
  final double amount;
  final String category;
  final bool isExpense;
  final int date;
  const FinanceEntry({required this.id, required this.description, required this.amount, required this.category, this.isExpense = true, this.date = 0});
}

class FinanceState {
  final List<FinanceEntry> entries;
  const FinanceState({this.entries = const []});
  FinanceState copyWith({List<FinanceEntry>? entries}) => FinanceState(entries: entries ?? this.entries);
  double get totalIncome => entries.where((e) => !e.isExpense).fold(0, (s, e) => s + e.amount);
  double get totalExpense => entries.where((e) => e.isExpense).fold(0, (s, e) => s + e.amount);
  double get balance => totalIncome - totalExpense;
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier() : super(const FinanceState());

  void addEntry(String description, double amount, String category, bool isExpense) {
    final entry = FinanceEntry(id: DateTime.now().millisecondsSinceEpoch.toString(), description: description, amount: amount, category: category, isExpense: isExpense, date: DateTime.now().millisecondsSinceEpoch);
    state = state.copyWith(entries: [...state.entries, entry]);
  }

  void deleteEntry(String id) => state = state.copyWith(entries: state.entries.where((e) => e.id != id).toList());
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) => FinanceNotifier());
