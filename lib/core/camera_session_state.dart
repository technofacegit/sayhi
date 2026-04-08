/// Lifecycle of the shared camera session used by chat video notes.
enum CameraSessionState {
  /// No controller or session not started.
  idle,

  /// [CameraController.initialize] and/or [prepareForVideoRecording] in progress.
  warmingUp,

  /// Ready to call [CameraController.startVideoRecording].
  ready,

  /// Warmup failed; record stays disabled until user retries navigation.
  error,
}
