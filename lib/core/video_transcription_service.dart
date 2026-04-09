import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// On-device transcription facade for video notes.
class VideoTranscriptionService {
  VideoTranscriptionService._();
  static final VideoTranscriptionService instance =
      VideoTranscriptionService._();
  static const MethodChannel _channel = MethodChannel(
    'qr_dating_app/video_transcription',
  );

  Future<String> transcribeVideoUrl(
    String videoUrl, {
    String localeCode = 'en',
  }) async {
    if (!(Platform.isIOS || Platform.isAndroid)) {
      throw UnsupportedError('Transcription is not available on this device');
    }
    if (Platform.isAndroid) {
      // TODO(android): Implement on-device transcription via Android Speech APIs
      // or a bundled offline STT engine (e.g. whisper.cpp bindings).
      throw UnsupportedError('Transcription is not available on this device');
    }

    final tempVideo = await _downloadToTempFile(videoUrl);
    try {
      final transcript = await _channel.invokeMethod<String>(
        'transcribeLocalVideo',
        {'filePath': tempVideo.path, 'locale': localeCode},
      );
      final out = transcript?.trim() ?? '';
      if (out.isEmpty) {
        throw Exception('empty_transcript');
      }
      return out;
    } on PlatformException catch (e) {
      if (e.code == 'unavailable') {
        throw UnsupportedError('Transcription is not available on this device');
      }
      rethrow;
    } finally {
      try {
        if (await tempVideo.exists()) {
          await tempVideo.delete();
        }
      } catch (_) {}
    }
  }

  Future<File> _downloadToTempFile(String videoUrl) async {
    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/transcribe_${DateTime.now().microsecondsSinceEpoch}.mp4',
    );
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(videoUrl));
      final resp = await req.close();
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('download_failed_${resp.statusCode}');
      }
      final sink = out.openWrite();
      await resp.forEach(sink.add);
      await sink.close();
      return out;
    } finally {
      client.close(force: true);
    }
  }
}
