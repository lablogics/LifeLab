import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
// Simple ID generator
import 'sync_queue.dart';

class SyncEngine {
  final ApiClient _api;
  final SyncQueue _queue;
  Timer? _syncTimer;
  bool _isSyncing = false;
  static int _idCounter = 0;
  static String _generateId() => '${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
  static const _maxRetries = 3;
  static const _syncInterval = Duration(minutes: 5);

  SyncEngine(this._api, this._queue);

  bool get isSyncing => _isSyncing;
  int get pendingCount => _queue.length;

  Future<void> initialize() async {
    await _queue.load();
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) => sync());
  }

  Future<void> enqueueCreate(String entityType, String entityId, Map<String, dynamic> data) async {
    final item = SyncQueueItem(
      id: _generateId(),
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.create,
      data: data,
      timestamp: DateTime.now(),
    );
    await _queue.enqueue(item);
  }

  Future<void> enqueueUpdate(String entityType, String entityId, Map<String, dynamic> data) async {
    final item = SyncQueueItem(
      id: _generateId(),
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.update,
      data: data,
      timestamp: DateTime.now(),
    );
    await _queue.enqueue(item);
  }

  Future<void> enqueueDelete(String entityType, String entityId) async {
    final item = SyncQueueItem(
      id: _generateId(),
      entityType: entityType,
      entityId: entityId,
      operation: SyncOperation.delete,
      timestamp: DateTime.now(),
    );
    await _queue.enqueue(item);
  }

  Future<void> sync() async {
    if (_isSyncing || _queue.isEmpty) return;
    _isSyncing = true;

    try {
      final items = List<SyncQueueItem>.from(_queue.items);
      for (final item in items) {
        try {
          await _processItem(item);
          await _queue.remove(item.id);
        } catch (e) {
          if (item.retryCount >= _maxRetries) {
            debugPrint('Sync failed after $_maxRetries retries: ${item.entityType} ${item.entityId}');
            await _queue.remove(item.id);
          } else {
            await _queue.updateRetryCount(item.id, item.retryCount + 1);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processItem(SyncQueueItem item) async {
    final endpoint = _getEndpoint(item.entityType);
    switch (item.operation) {
      case SyncOperation.create:
        await _api.dio.dio.post(endpoint, data: item.data);
        break;
      case SyncOperation.update:
        await _api.dio.dio.put('$endpoint/${item.entityId}', data: item.data);
        break;
      case SyncOperation.delete:
        await _api.dio.dio.delete('$endpoint/${item.entityId}');
        break;
    }
  }

  String _getEndpoint(String entityType) {
    switch (entityType) {
      case 'note':
        return Endpoints.notes;
      case 'todo':
        return Endpoints.todos;
      case 'project':
        return Endpoints.projects;
      default:
        throw Exception('Unknown entity type: $entityType');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
