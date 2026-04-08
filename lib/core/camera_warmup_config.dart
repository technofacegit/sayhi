import 'package:camera/camera.dart';

/// Settings used when [CameraWarmupService] creates its [CameraController].
///
/// Assign `CameraWarmupService.instance.config` **before** the first chat opens
/// (e.g. in `main()` after bootstrap) so [beginChatSession] picks the preset.
/// Example: `CameraWarmupService.instance.config = CameraWarmupConfig.lowNoAudio;`
class CameraWarmupConfig {
  const CameraWarmupConfig({
    this.resolutionPreset = ResolutionPreset.medium,
    this.enableAudio = true,
  });

  final ResolutionPreset resolutionPreset;
  final bool enableAudio;

  /// experiment label for logs, e.g. `medium+audio`
  String get experimentLabel =>
      '${resolutionPreset.name}+${enableAudio ? 'audio' : 'noAudio'}';

  // --- Presets for A/B tests ---

  static const CameraWarmupConfig mediumWithAudio = CameraWarmupConfig(
    resolutionPreset: ResolutionPreset.medium,
    enableAudio: true,
  );

  static const CameraWarmupConfig lowWithAudio = CameraWarmupConfig(
    resolutionPreset: ResolutionPreset.low,
    enableAudio: true,
  );

  static const CameraWarmupConfig mediumNoAudio = CameraWarmupConfig(
    resolutionPreset: ResolutionPreset.medium,
    enableAudio: false,
  );

  static const CameraWarmupConfig lowNoAudio = CameraWarmupConfig(
    resolutionPreset: ResolutionPreset.low,
    enableAudio: false,
  );

  static const CameraWarmupConfig highWithAudio = CameraWarmupConfig(
    resolutionPreset: ResolutionPreset.high,
    enableAudio: true,
  );
}
