import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SyncOperation { create, update, delete }

class SyncQueueItem {
  final String id;
  final String entityType; // 'note', 'todo', 'project', etc.
  final String entityId;
  final SyncOperation operation;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final int retryCount;

  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'operation': operation.index,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: SyncOperation.values[json['operation'] as int],
      data: json['data'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  SyncQueueItem copyWith({int? retryCount}) {
    return SyncQueueItem(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class SyncQueue {
  static const _storageKey = 'sync_queue';
  final FlutterSecureStorage _storage;
  List<SyncQueueItem> _queue = [];

  SyncQueue(this._storage);

  List<SyncQueueItem> get items => List.unmodifiable(_queue);
  int get length => _queue.length;
  bool get isEmpty => _queue.isEmpty;

  Future<void> load() async {
    final jsonStr = await _storage.read(key: _storageKey);
    if (jsonStr != null) {
      final List<dynamic> jsonList = json.decode(jsonStr) as List;
      _queue = jsonList.map((e) => SyncQueueItem.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _save() async {
    final jsonList = _queue.map((e) => e.toJson()).toList();
    await _storage.write(key: _storageKey, value: json.encode(jsonList));
  }

  Future<void> enqueue(SyncQueueItem item) async {
    _queue.add(item);
    await _save();
  }

  Future<void> remove(String itemId) async {
    _queue.removeWhere((item) => item.id == itemId);
    await _save();
  }

  Future<void> updateRetryCount(String itemId, int retryCount) async {
    final index = _queue.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(retryCount: retryCount);
      await _save();
    }
  }

  Future<void> clear() async {
    _queue.clear();
    await _storage.delete(key: _storageKey);
  }
}
