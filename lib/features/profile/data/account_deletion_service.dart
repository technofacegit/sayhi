import 'package:http/http.dart' as http;
import 'package:qr_dating_app/core/auth_session.dart';
import 'package:qr_dating_app/core/supabase_project.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Deletes the current auth user via GoTrue `DELETE /auth/v1/user` (requires valid JWT).
class AccountDeletionService {
  AccountDeletionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> deleteCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Not signed in');
    }
    final uri = Uri.parse(kSupabaseProjectUrl).replace(path: '/auth/v1/user');
    final res = await http.delete(
      uri,
      headers: {
        'apikey': kSupabaseAnonKey,
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      final body = res.body.isNotEmpty ? res.body : 'HTTP ${res.statusCode}';
      throw Exception(body);
    }
    await _client.auth.signOut();
    AuthSession.signOut();
  }
}
