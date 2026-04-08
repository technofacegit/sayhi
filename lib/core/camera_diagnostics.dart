import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Structured debug logs for camera perf experiments (grep `[camera]`).
void cameraDiag(
  String event, {
  required int elapsedMs,
  ResolutionPreset? preset,
  bool? enableAudio,
  bool? controllerReused,
  bool? controllerRecreated,
  int? recordingStartIndex,
  String? extra,
}) {
  if (!kDebugMode) return;
  final buf = StringBuffer('[camera] $event ${elapsedMs}ms');
  if (preset != null) buf.write(' preset=${preset.name}');
  if (enableAudio != null) buf.write(' audio=$enableAudio');
  if (controllerReused != null) buf.write(' reused=$controllerReused');
  if (controllerRecreated != null) buf.write(' recreated=$controllerRecreated');
  if (recordingStartIndex != null) {
    buf.write(' start#$recordingStartIndex');
  }
  if (extra != null) buf.write(' $extra');
  debugPrint(buf.toString());
}
