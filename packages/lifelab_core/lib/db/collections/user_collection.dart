import 'package:isar/isar.dart';
part 'user_collection.g.dart';

@collection
class UserCollection {
  Id id = Isar.autoIncrement;
  String? remoteId;
  String? email;
  String? name;
  DateTime? createdAt;
  DateTime? updatedAt;
}
