import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'sync_engine.dart';
import 'sync_queue.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final syncQueueProvider = Provider<SyncQueue>((ref) {
  return SyncQueue(ref.watch(secureStorageProvider));
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(ref.watch(apiClientProvider), ref.watch(syncQueueProvider));
  engine.initialize();
  ref.onDispose(() => engine.dispose());
  return engine;
});

final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  return SyncStateNotifier(ref.watch(syncEngineProvider));
});

class SyncState {
  final int pendingCount;
  final bool isSyncing;
  final DateTime? lastSynced;

  const SyncState({
    this.pendingCount = 0,
    this.isSyncing = false,
    this.lastSynced,
  });

  SyncState copyWith({int? pendingCount, bool? isSyncing, DateTime? lastSynced}) {
    return SyncState(
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }
}

class SyncStateNotifier extends StateNotifier<SyncState> {
  final SyncEngine _engine;

  SyncStateNotifier(this._engine) : super(const SyncState()) {
    _updateState();
  }

  void _updateState() {
    state = state.copyWith(
      pendingCount: _engine.pendingCount,
      isSyncing: _engine.isSyncing,
    );
  }

  Future<void> sync() async {
    state = state.copyWith(isSyncing: true);
    await _engine.sync();
    state = state.copyWith(isSyncing: false, lastSynced: DateTime.now());
    _updateState();
  }
}
