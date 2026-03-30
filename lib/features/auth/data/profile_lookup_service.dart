import 'package:supabase_flutter/supabase_flutter.dart';

/// [profiles.email] + RPC [profile_exists_by_email] (bkz. supabase/migrations).
/// RPC yoksa (PGRST202) yalnızca [profiles] tablosunda e-posta eşleşmesi denenir;
/// tam davranış için migration’ı Supabase’de çalıştırın.
class ProfileLookupService {
  ProfileLookupService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Bu e-posta sistemde kayıtlı mı (profil veya auth.users)?
  Future<bool> emailExistsInProfiles(String email) async {
    final trimmed = email.trim();
    try {
      final result = await _client.rpc<dynamic>(
        'profile_exists_by_email',
        params: {'lookup_email': trimmed},
      );
      if (result is bool) return result;
      return result == true;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        return _fallbackProfilesTableOnly(trimmed);
      }
      rethrow;
    }
  }

  /// RPC kurulu değilken: sadece [profiles.email] (auth.users kontrolü yok).
  Future<bool> _fallbackProfilesTableOnly(String email) async {
    final row = await _client
        .from('profiles')
        .select('id')
        .eq('email', email)
        .maybeSingle();
    return row != null;
  }
}
