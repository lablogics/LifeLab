import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_providers.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddDialog(context, ref), child: const Icon(Icons.add)),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: _SummaryCard(title: 'Income', amount: state.totalIncome, color: Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _SummaryCard(title: 'Expense', amount: state.totalExpense, color: Colors.red)),
          const SizedBox(width: 8),
          Expanded(child: _SummaryCard(title: 'Balance', amount: state.balance, color: theme.colorScheme.primary)),
        ])),
        const Divider(),
        Expanded(child: state.entries.isEmpty
            ? Center(child: Text('No entries yet', style: theme.textTheme.bodyLarge))
            : ListView.builder(itemCount: state.entries.length, itemBuilder: (ctx, i) {
                final e = state.entries[i];
                return ListTile(leading: Icon(e.isExpense ? Icons.arrow_downward : Icons.arrow_upward, color: e.isExpense ? Colors.red : Colors.green), title: Text(e.description), subtitle: Text(e.category), trailing: Text('${e.isExpense ? '-' : '+'}${e.amount.toStringAsFixed(2)}', style: TextStyle(color: e.isExpense ? Colors.red : Colors.green, fontWeight: FontWeight.bold)));
              })),
      ]),
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
