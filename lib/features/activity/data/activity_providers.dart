import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifelab_core/api/api_client.dart';
import 'package:lifelab_core/api/endpoints.dart';
import 'package:lifelab_core/di/core_providers.dart';

class ActivityItem {
  final String id; final String action; final String entityType; final String? entityId; final String? description; final int? createdAt;
  const ActivityItem({required this.id, required this.action, required this.entityType, this.entityId, this.description, this.createdAt});
  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    id: json['id'] as String, action: json['action'] as String? ?? '', entityType: json['entityType'] as String? ?? '',
    entityId: json['entityId'] as String?, description: json['description'] as String? ?? json['detail'] as String?,
    createdAt: json['createdAt'] as int?);
}

class ActivityState {
  final List<ActivityItem> items; final bool isLoading;
  const ActivityState({this.items = const [], this.isLoading = false});
  ActivityState copyWith({List<ActivityItem>? items, bool? isLoading}) => ActivityState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading);
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  final ApiClient _api;
  ActivityNotifier(this._api) : super(const ActivityState());
  Future<void> loadActivity({int limit = 50}) async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _api.dio.dio.get(Endpoints.activity, queryParameters: {'limit': limit});
      final list = (r.data as List? ?? []).map((e) => ActivityItem.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) { state = state.copyWith(isLoading: false); }
  }
}

final activityProvider = StateNotifierProvider<ActivityNotifier, ActivityState>((ref) => ActivityNotifier(ref.watch(apiClientProvider)));
