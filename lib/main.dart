import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_dating_app/core/perf_log.dart';

import 'app/app_startup.dart';
import 'bootstrap.dart';

void main() {
  final sw = Stopwatch()..start();
  perfLog(
    'main',
    'ensureInitialized + bootstrap (camera warmup from chat)',
    sw,
  );
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrapFuture = bootstrap();
  unawaited(
    bootstrapFuture.then((_) {
      perfLog('main', 'bootstrap() Future complete', sw);
    }),
  );
  runApp(AppStartup(bootstrapFuture: bootstrapFuture));
}
