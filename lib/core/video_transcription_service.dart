import 'dart:io';

/// On-device transcription facade for video notes.
///
/// Current implementation reports unsupported because there is no integrated
/// offline speech-to-text engine in this app yet.
class VideoTranscriptionService {
  VideoTranscriptionService._();
  static final VideoTranscriptionService instance =
      VideoTranscriptionService._();

  Future<String> transcribeVideoUrl(String videoUrl) async {
    if (!(Platform.isIOS || Platform.isAndroid)) {
      throw UnsupportedError(
        'Transcription is not available on this device',
      );
    }
    throw UnsupportedError(
      'Transcription is not available on this device',
    );
  }
}
