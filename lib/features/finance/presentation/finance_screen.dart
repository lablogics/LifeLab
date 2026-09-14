import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_providers.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});
  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String _selectedAccount = 'all';
  String _categoryFilter = '';
  String _searchQuery = '';
  bool _showChart = false;

  List<String> get _accounts {
    final entries = ref.read(financeProvider).entries;
    return ['all', ...entries.map((e) => e.category).toSet()];
  }

  List<String> get _categories {
    final entries = ref.read(financeProvider).entries;
    return entries.map((e) => e.category).toSet().toList()..sort();
  }

  List<FinanceEntry> get _filteredEntries {
    var entries = ref.read(financeProvider).entries;
    if (_selectedAccount != 'all') {
      entries = entries.where((e) => e.category == _selectedAccount).toList();
    }
    if (_categoryFilter.isNotEmpty) {
      entries = entries.where((e) => e.category == _categoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      entries = entries.where((e) => e.description.toLowerCase().contains(q) || e.category.toLowerCase().contains(q)).toList();
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final theme = Theme.of(context);
    final entries = _filteredEntries;
    final income = entries.where((e) => !e.isExpense).fold(0.0, (s, e) => s + e.amount);
    final expense = entries.where((e) => e.isExpense).fold(0.0, (s, e) => s + e.amount);
    final balance = income - expense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        actions: [
          IconButton(icon: Icon(_showChart ? Icons.list : Icons.bar_chart), tooltip: _showChart ? 'List view' : 'Chart view', onPressed: () => setState(() => _showChart = !_showChart)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _categoryFilter = v == _categoryFilter ? '' : v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: '', child: Text('All Categories')),
              ..._categories.map((c) => PopupMenuItem(value: c, child: Text(c))),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: TextField(
            decoration: const InputDecoration(hintText: 'Search entries...', prefixIcon: Icon(Icons.search), isDense: true, border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _searchQuery = v),
          )),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddDialog(context, ref), child: const Icon(Icons.add)),
      body: Column(children: [
        // Summary cards
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: _SummaryCard(title: 'Income', amount: income, color: Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _SummaryCard(title: 'Expense', amount: expense, color: Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _SummaryCard(title: 'Balance', amount: balance, color: theme.colorScheme.primary)),
        ])),
        // Account selector chips
        if (_accounts.length > 1)
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            const SizedBox(width: 16),
            ..._accounts.map((a) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(label: Text(a == 'all' ? 'All' : a), selected: _selectedAccount == a, onSelected: (_) => setState(() => _selectedAccount = a)),
            )),
            const SizedBox(width: 16),
          ])),
        if (_categoryFilter.isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Text('Filtered: $_categoryFilter', style: theme.textTheme.labelSmall),
            const Spacer(),
            TextButton(onPressed: () => setState(() => _categoryFilter = ''), child: const Text('Clear')),
          ])),
        const Divider(),
        // Chart or list
        Expanded(child: _showChart
          ? _buildChart(entries, theme)
          : entries.isEmpty
            ? Center(child: Text('No entries', style: theme.textTheme.bodyLarge))
            : ListView.builder(itemCount: entries.length, itemBuilder: (ctx, i) {
                final e = entries[i];
                return ListTile(
                  leading: Icon(e.isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: e.isExpense ? Colors.red : Colors.green),
                  title: Text(e.description),
                  subtitle: Text(e.category),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${e.isExpense ? '-' : '+'}${e.amount.toStringAsFixed(2)}', style: TextStyle(color: e.isExpense ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red), onPressed: () => ref.read(financeProvider.notifier).deleteEntry(e.id)),
                  ]),
                );
              })),
      ]),
    );
  }

  Widget _buildChart(List<FinanceEntry> entries, ThemeData theme) {
    // Simple category breakdown bar chart
    final categoryTotals = <String, double>{};
    for (final e in entries.where((e) => e.isExpense)) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    final sorted = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return Center(child: Text('No expense data for chart', style: theme.textTheme.bodyLarge));
    final maxVal = sorted.first.value;
    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.teal, Colors.blue, Colors.purple, Colors.pink, Colors.indigo];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Expense by Category', style: theme.textTheme.titleSmall));
        final entry = sorted[i - 1];
        final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
        return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          SizedBox(width: 80, child: Text(entry.key, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 20, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: colors[i % colors.length].withOpacity(0.2)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: ratio, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: colors[i % colors.length]))))),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Text(entry.value.toStringAsFixed(0), style: theme.textTheme.bodySmall, textAlign: TextAlign.right)),
        ]));
      },
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    bool isExpense = true;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      title: const Text('Add Entry'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [Expanded(child: ChoiceChip(label: const Text('Expense'), selected: isExpense, onSelected: (v) => setDialogState(() => isExpense = v))), const SizedBox(width: 8), Expanded(child: ChoiceChip(label: const Text('Income'), selected: !isExpense, onSelected: (v) => setDialogState(() => isExpense = !v)))]),
        TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
        TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () { ref.read(financeProvider.notifier).addEntry(descCtrl.text, double.tryParse(amountCtrl.text) ?? 0, catCtrl.text, isExpense); Navigator.pop(ctx); }, child: const Text('Add'))],
    )));
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  const _SummaryCard({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [Text(title, style: theme.textTheme.labelSmall), const SizedBox(height: 4), Text(amount.toStringAsFixed(2), style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold))])));
  }
}
