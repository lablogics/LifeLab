import 'package:isar/isar.dart';
import 'collections/user_collection.dart';
import 'collections/sync_meta_collection.dart';

class IsarDatabase {
  Isar? _isar;

  Future<void> init(String directory) async {
    if (_isar != null) return;
    _isar = await Isar.open(
      [UserCollectionSchema, SyncMetaCollectionSchema],
      directory: directory,
    );
  }

  Isar get instance {
    if (_isar == null) throw StateError('Database not initialized. Call init() first.');
    return _isar!;
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
