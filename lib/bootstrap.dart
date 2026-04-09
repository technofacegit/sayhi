import 'dart:async';

import 'package:qr_dating_app/core/auth_session.dart';
import 'package:qr_dating_app/core/perf_log.dart';
import 'package:qr_dating_app/core/supabase_project.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap() async {
  final sw = Stopwatch()..start();
  perfLog('bootstrap', 'Supabase.initialize starting', sw);
  await Supabase.initialize(
    url: kSupabaseProjectUrl,
    anonKey: kSupabaseAnonKey,
  );
  perfLog('bootstrap', 'Supabase.initialize done', sw);

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
