import 'package:isar/isar.dart';
part 'sync_meta_collection.g.dart';

@collection
class SyncMetaCollection {
  Id id = Isar.autoIncrement;
  String entityType = '';
  String entityId = '';
  @enumerated
  SyncStatus status = SyncStatus.pending;
  DateTime? syncedAt;
  DateTime createdAt = DateTime.now();
}

enum SyncStatus { pending, synced, conflict }
