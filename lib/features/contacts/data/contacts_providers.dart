import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';
import 'models/contact_model.dart';

class ContactsState {
  final List<ContactModel> contacts;
  final bool isLoading;
  final String? error;

  const ContactsState({this.contacts = const [], this.isLoading = false, this.error});

  ContactsState copyWith({List<ContactModel>? contacts, bool? isLoading, String? error}) {
    return ContactsState(contacts: contacts ?? this.contacts, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  final ApiClient _api;
  ContactsNotifier(this._api) : super(const ContactsState()) { loadContacts(); }

  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.contacts);
      final list = (r.data as List).map((e) => ContactModel.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(contacts: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false, error: e.toString()); }
  }

  Future<void> createContact(ContactModel c) async {
    try {
      await _api.dio.dio.post(Endpoints.contacts, data: c.toJson());
      await loadContacts();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> updateContact(ContactModel c) async {
    try {
      await _api.dio.dio.put('${Endpoints.contacts}/${c.id}', data: c.toJson());
      await loadContacts();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> deleteContact(String id) async {
    try {
      await _api.dio.dio.delete('${Endpoints.contacts}/$id');
      await loadContacts();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }

  Future<void> importContacts(String jsonData) async {
    try {
      await _api.dio.dio.post('${Endpoints.contacts}/import', data: {'data': jsonData});
      await loadContacts();
    } catch (e) { state = state.copyWith(error: e.toString()); }
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  return ContactsNotifier(ref.watch(apiClientProvider));
});
