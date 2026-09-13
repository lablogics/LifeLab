import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/messages_providers.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  final String contactId;
  final String contactName;
  const MessagesScreen({super.key, required this.contactId, required this.contactName});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(messagesProvider.notifier).loadMessages(widget.contactId));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.contactName)),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                    ? Center(child: Text('No messages yet', style: theme.textTheme.bodyLarge))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        itemCount: state.messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = state.messages[i];
                          final isOut = msg.direction == 'outbound';
                          return Align(
                            alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isOut ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg.content,
                                style: TextStyle(color: isOut ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (_inputCtrl.text.trim().isNotEmpty) {
                        ref.read(messagesProvider.notifier).sendMessage(widget.contactId, _inputCtrl.text, 'outbound');
                        _inputCtrl.clear();
                        ref.read(messagesProvider.notifier).loadMessages(widget.contactId);
                      }
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
