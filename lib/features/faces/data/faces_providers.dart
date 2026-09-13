import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class PersonModel {
  final String id;
  final String name;
  final int? photoCount;
  final String? faceUrl;
  const PersonModel({required this.id, required this.name, this.photoCount, this.faceUrl});
  factory PersonModel.fromJson(Map<String, dynamic> json) => PersonModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Unknown',
    photoCount: json['photoCount'] as int?,
    faceUrl: json['faceUrl'] as String?);
}

class FacesState {
  final List<PersonModel> people;
  final bool isLoading;
  final String? error;
  const FacesState({this.people = const [], this.isLoading = false, this.error});
  FacesState copyWith({List<PersonModel>? people, bool? isLoading, String? error}) =>
    FacesState(people: people ?? this.people, isLoading: isLoading ?? this.isLoading, error: error);
}

class FacesNotifier extends StateNotifier<FacesState> {
  final ApiClient _api;
  FacesNotifier(this._api) : super(const FacesState());

  Future<void> loadPeople() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.facesPeople);
      final list = (r.data as List? ?? []).map((e) => PersonModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(people: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> renamePerson(String id, String name) async {
    try {
      await _api.dio.dio.put('${Endpoints.facesPeople}/$id', data: {'name': name});
      loadPeople();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() async => loadPeople();
}

final facesProvider = StateNotifierProvider<FacesNotifier, FacesState>((ref) =>
  FacesNotifier(ref.watch(apiClientProvider)));
