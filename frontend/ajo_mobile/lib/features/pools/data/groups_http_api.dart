import '../../../core/network/api_client.dart';

class GroupSummary {
  const GroupSummary({
    required this.id,
    required this.name,
    this.description,
    required this.type,
  });

  final String id;
  final String name;
  final String? description;
  final String type;
}

class GroupsHttpApi {
  GroupsHttpApi({required this.client});

  final ApiClient client;

  Future<List<GroupSummary>> searchGroups({required String q}) async {
    final res = await client.getJson(
      '/groups',
      query: <String, String>{'q': q},
    );

    final data = (res is Map<String, dynamic> ? res['data'] : null);
    final list = (data is List) ? data : const <dynamic>[];

    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return GroupSummary(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        description: m['description']?.toString(),
        type: m['type']?.toString() ?? '',
      );
    }).toList();
  }

  Future<void> requestJoinGroup({required String groupId}) async {
    await client.postJsonNoBody(
      '/groups/$groupId/request',
    );
  }
}
