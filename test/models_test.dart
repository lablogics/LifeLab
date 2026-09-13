import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab/features/photos/data/photos_providers.dart';
import 'package:lifelab/features/drive/data/drive_providers.dart';
import 'package:lifelab/features/albums/data/albums_providers.dart';
import 'package:lifelab/features/faces/data/faces_providers.dart';

void main() {
  group('PhotoModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'p1', 'name': 'test.jpg', 'mimeType': 'image/jpeg',
        'size': 1024, 'starred': true, 'favorite': false, 'trashed': false,
        'width': 1920, 'height': 1080, 'cameraModel': 'iPhone',
        'latitude': 33.5, 'longitude': -7.6,
      };
      final photo = PhotoModel.fromJson(json);
      expect(photo.id, 'p1');
      expect(photo.name, 'test.jpg');
      expect(photo.starred, true);
      expect(photo.width, 1920);
      expect(photo.latitude, 33.5);
    });

    test('fromJson handles missing optional fields', () {
      final json = {'id': 'p2', 'name': 'photo.png'};
      final photo = PhotoModel.fromJson(json);
      expect(photo.id, 'p2');
      expect(photo.mimeType, null);
      expect(photo.starred, false);
    });
  });

  group('DriveItem', () {
    test('fromJson parses file', () {
      final json = {'id': 'd1', 'name': 'doc.pdf', 'type': 'file', 'size': 2048};
      final item = DriveItem.fromJson(json);
      expect(item.id, 'd1');
      expect(item.type, 'file');
      expect(item.size, 2048);
    });

    test('fromJson parses folder', () {
      final json = {'id': 'd2', 'name': 'Documents', 'type': 'folder', 'parentId': 'root'};
      final item = DriveItem.fromJson(json);
      expect(item.type, 'folder');
      expect(item.parentId, 'root');
    });
  });

  group('AlbumModel', () {
    test('fromJson parses correctly', () {
      final json = {'id': 'a1', 'name': 'Vacation', 'photoCount': 42};
      final album = AlbumModel.fromJson(json);
      expect(album.id, 'a1');
      expect(album.name, 'Vacation');
      expect(album.photoCount, 42);
    });
  });

  group('PersonModel', () {
    test('fromJson parses correctly', () {
      final json = {'id': 'f1', 'name': 'John', 'photoCount': 15};
      final person = PersonModel.fromJson(json);
      expect(person.id, 'f1');
      expect(person.name, 'John');
      expect(person.photoCount, 15);
    });

    test('fromJson defaults name to Unknown', () {
      final json = {'id': 'f2'};
      final person = PersonModel.fromJson(json);
      expect(person.name, 'Unknown');
    });
  });

  group('PhotosState', () {
    test('filtered returns all when search is empty', () {
      const state = PhotosState(photos: [
        PhotoModel(id: '1', name: 'a.jpg'),
        PhotoModel(id: '2', name: 'b.png'),
      ]);
      expect(state.filtered.length, 2);
    });

    test('filtered narrows by search query', () {
      const state = PhotosState(
        photos: [PhotoModel(id: '1', name: 'sunset.jpg'), PhotoModel(id: '2', name: 'mountain.jpg')],
        searchQuery: 'sunset',
      );
      expect(state.filtered.length, 1);
      expect(state.filtered.first.name, 'sunset.jpg');
    });

    test('copyWith preserves unchanged fields', () {
      const state = PhotosState(searchQuery: 'test');
      final updated = state.copyWith(isLoading: true);
      expect(updated.searchQuery, 'test');
      expect(updated.isLoading, true);
    });
  });

  group('DriveState', () {
    test('copyWith updates path navigation', () {
      const state = DriveState(path: ['root'], pathNames: ['Home']);
      final updated = state.copyWith(path: ['root', 'sub'], pathNames: ['Home', 'Docs']);
      expect(updated.path.length, 2);
      expect(updated.pathNames.last, 'Docs');
    });
  });
}
