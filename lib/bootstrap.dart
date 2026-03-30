import 'package:qr_dating_app/core/auth_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap() async {
  await Supabase.initialize(
    url: 'https://iqedtjrhxfzdcxnunmic.supabase.co',
    anonKey: 'sb_publishable_JEppoEJ661oWAUlGZ71arg_vXoz3d43',
  );

  void syncAuthSessionFromSupabase() {
    if (Supabase.instance.client.auth.currentSession != null) {
      AuthSession.signIn();
    } else {
      AuthSession.signOut();
    }
  }

  syncAuthSessionFromSupabase();

  Supabase.instance.client.auth.onAuthStateChange.listen((_) {
    syncAuthSessionFromSupabase();
  });
}

