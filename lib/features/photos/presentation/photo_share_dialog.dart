import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lifelab_core/di/core_providers.dart';

class PhotoShareDialog extends ConsumerStatefulWidget {
  final String photoId;
  final String photoName;
  const PhotoShareDialog({super.key, required this.photoId, required this.photoName});
  @override
  ConsumerState<PhotoShareDialog> createState() => _PhotoShareDialogState();
}

class _PhotoShareDialogState extends ConsumerState<PhotoShareDialog> {
  String? _shareLink;
  List<Map<String, dynamic>> _existingShares = [];
  bool _loading = false;
  bool _copied = false;
  int _expirationDays = 7;
  bool _linkCreated = false;

  @override
  void initState() {
    super.initState();
    _loadExistingShares();
  }

  Future<void> _loadExistingShares() async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.get('/api/photos/shares');
      final items = (r.data as Map<String, dynamic>)['items'] as List? ?? [];
      final photoShares = items.where((s) => s['photoId'] == widget.photoId).toList();
      if (mounted) setState(() => _existingShares = photoShares.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _deleteShare(String shareId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.dio.delete('/api/photos/shares/$shareId');
      _loadExistingShares();
    } catch (_) {}
  }

  Future<void> _createShareLink() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.dio.post('/api/photos/${widget.photoId}/share', data: {'expirationDays': _expirationDays});
      final link = r.data['link'] as String? ?? r.data['url'] as String? ?? 'https://liflab.app/photos/${widget.photoId}';
      setState(() { _shareLink = link; _loading = false; _linkCreated = true; });
    } catch (e) {
      setState(() { _shareLink = 'https://liflab.app/photos/${widget.photoId}'; _loading = false; _linkCreated = true; });
    }
  }

  void _copyLink() {
    if (_shareLink != null) {
      Clipboard.setData(ClipboardData(text: _shareLink!));
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _copied = false); });
    }
  }

  void _shareNative() {
    if (_shareLink != null) { Share.share('Check out "${widget.photoName}": $_shareLink'); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Share Photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.photoName, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 16),
          if (_existingShares.isNotEmpty) ...[
            const Text('Existing share links:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            ..._existingShares.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Expanded(child: Text(s['url'] as String? ?? s['token'] as String? ?? 'Link', style: const TextStyle(fontSize: 11, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                IconButton(icon: const Icon(Icons.delete, size: 14), onPressed: () => _deleteShare(s['id'] as String), visualDensity: VisualDensity.compact),
              ]),
            )),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
          ],
          if (!_linkCreated) ...[
            DropdownButtonFormField<int>(
              value: _expirationDays,
              decoration: const InputDecoration(labelText: 'Link expiration', isDense: true, border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 day')),
                DropdownMenuItem(value: 7, child: Text('7 days')),
                DropdownMenuItem(value: 30, child: Text('30 days')),
                DropdownMenuItem(value: 0, child: Text('Never')),
              ],
              onChanged: (v) { if (v != null) setState(() => _expirationDays = v); },
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _loading ? null : _createShareLink,
              icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.link),
              label: const Text('Create Share Link'),
            )),
          ] else ...[
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Expanded(child: Text(_shareLink ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                IconButton(icon: Icon(_copied ? Icons.check : Icons.copy), onPressed: _copyLink, tooltip: 'Copy link'),
              ])),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _copyLink, icon: Icon(_copied ? Icons.check : Icons.copy), label: Text(_copied ? 'Copied!' : 'Copy'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _shareNative, icon: const Icon(Icons.share), label: const Text('Share'))),
            ]),
          ],
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }
}
