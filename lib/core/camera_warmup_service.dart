import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'camera_diagnostics.dart';
import 'camera_session_state.dart';
import 'camera_warmup_config.dart';

/// Shared camera session for chat video notes.
///
/// **Why the first [CameraController.startVideoRecording] can still take seconds on iOS:**
/// `initialize` + `prepareForVideoRecording` bring up preview and pipeline hints, but
/// AVFoundation may still defer encoder/session wiring until the first real recording
/// start. After that, subsequent starts are cheap (~tens of ms).
///
/// **This service** keeps one [CameraController] alive for the chat screen, warms on
/// [beginChatSession], and releases on [releaseChatSession]. That shifts heavy work
/// to screen open instead of the first long-press. It does **not** use fake
/// start/stop recording.
class CameraWarmupService {
  CameraWarmupService._();
  static final CameraWarmupService instance = CameraWarmupService._();

  /// Override before [beginChatSession] for A/B tests.
  CameraWarmupConfig config = CameraWarmupConfig.mediumWithAudio;

  final ValueNotifier<CameraSessionState> sessionState =
      ValueNotifier<CameraSessionState>(CameraSessionState.idle);

  CameraController? _controller;
  Future<void>? _warmupFuture;
  int _configGeneration = 0;
  int _successfulRecordingStarts = 0;

  CameraController? get controller => _controller;

  /// True after at least one successful [startVideoRecording] in this process.
  bool get hasSuccessfulRecordingStart => _successfulRecordingStarts > 0;

  /// Call when entering the chat screen (e.g. [State.initState]). Warms camera early.
  Future<void> beginChatSession() async {
    if (_isWarm) {
      sessionState.value = CameraSessionState.ready;
      return;
    }
    sessionState.value = CameraSessionState.warmingUp;
    try {
      await ensureSessionReady();
      if (_isWarm) {
        sessionState.value = CameraSessionState.ready;
      } else {
        sessionState.value = CameraSessionState.error;
      }
    } catch (e, st) {
      debugPrint('[camera] beginChatSession failed: $e\n$st');
      sessionState.value = CameraSessionState.error;
    }
  }

  /// Call when leaving the chat screen ([State.dispose]). Disposes the controller.
  Future<void> releaseChatSession() async {
    _successfulRecordingStarts = 0;
    await disposeController();
    sessionState.value = CameraSessionState.idle;
  }

  /// Idempotent: creates/initializes controller if needed. Safe from record path.
  Future<void> ensureSessionReady() async {
    if (_isWarm) return;
    _warmupFuture ??= _runWarmup(_configGeneration);
    try {
      await _warmupFuture;
    } finally {
      _warmupFuture = null;
    }
    if (!_isWarm) {
      throw StateError('Camera session not ready after warmup');
    }
  }

  bool get _isWarm =>
      _controller != null &&
      _controller!.value.isInitialized &&
      !_controller!.value.hasError;

  /// Dispose controller (e.g. on chat pop). Next [ensureSessionReady] recreates.
  Future<void> disposeController() async {
    _configGeneration++;
    _warmupFuture = null;
    final c = _controller;
    _controller = null;
    if (c != null) {
      try {
        await c.dispose();
      } catch (e) {
        debugPrint('[camera] disposeController: $e');
      }
    }
  }

  /// Call from UI after [startVideoRecording] returns successfully (not aborted).
  void notifyRecordingStartCompleted({required int elapsedMs}) {
    _successfulRecordingStarts++;
    cameraDiag(
      'startVideoRecording',
      elapsedMs: elapsedMs,
      preset: config.resolutionPreset,
      enableAudio: config.enableAudio,
      recordingStartIndex: _successfulRecordingStarts,
    );
  }

  Future<void> _runWarmup(int gen) async {
    final swAll = Stopwatch()..start();

    final swList = Stopwatch()..start();
    final cameras = await availableCameras();
    swList.stop();
    cameraDiag(
      'availableCameras',
      elapsedMs: swList.elapsedMilliseconds,
      preset: config.resolutionPreset,
      enableAudio: config.enableAudio,
    );

    if (gen != _configGeneration) return;

    final cam = cameras.isNotEmpty
        ? cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          )
        : null;
    if (cam == null) {
      throw StateError('No cameras available');
    }

    final old = _controller;
    if (old != null) {
      try {
        await old.dispose();
      } catch (_) {}
      _controller = null;
    }

    final ctrl = CameraController(
      cam,
      config.resolutionPreset,
      enableAudio: config.enableAudio,
    );
    _controller = ctrl;

    try {
      final swInit = Stopwatch()..start();
      await ctrl.initialize();
      swInit.stop();
      cameraDiag(
        'controller.initialize',
        elapsedMs: swInit.elapsedMilliseconds,
        preset: config.resolutionPreset,
        enableAudio: config.enableAudio,
        controllerReused: false,
        controllerRecreated: old != null,
      );

      if (gen != _configGeneration) {
        await _disposeCtrlIfCurrent(ctrl);
        return;
      }

      final swPrep = Stopwatch()..start();
      await ctrl.prepareForVideoRecording();
      swPrep.stop();
      cameraDiag(
        'prepareForVideoRecording',
        elapsedMs: swPrep.elapsedMilliseconds,
        preset: config.resolutionPreset,
        enableAudio: config.enableAudio,
        controllerReused: false,
        controllerRecreated: old != null,
      );
    } catch (e) {
      await _disposeCtrlIfCurrent(ctrl);
      rethrow;
    }

    if (gen != _configGeneration) {
      await _disposeCtrlIfCurrent(ctrl);
      return;
    }

    swAll.stop();
    cameraDiag(
      'warmup_total',
      elapsedMs: swAll.elapsedMilliseconds,
      preset: config.resolutionPreset,
      enableAudio: config.enableAudio,
      extra: 'exp=${config.experimentLabel}',
    );
  }

  /// Legacy alias — prefer [ensureSessionReady].
  Future<void> warmup() => ensureSessionReady();

  Future<void> _disposeCtrlIfCurrent(CameraController ctrl) async {
    try {
      await ctrl.dispose();
    } catch (_) {}
    if (_controller == ctrl) {
      _controller = null;
    }
  }
}
