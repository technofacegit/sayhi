import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let transcriptionChannelName = "qr_dating_app/video_transcription"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: transcriptionChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleTranscriptionCall(call: call, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleTranscriptionCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "transcribeLocalVideo" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let args = call.arguments as? [String: Any],
      let filePath = args["filePath"] as? String,
      let locale = args["locale"] as? String
    else {
      result(
        FlutterError(
          code: "bad_args",
          message: "Missing filePath or locale",
          details: nil
        )
      )
      return
    }

    let authStatus = SFSpeechRecognizer.authorizationStatus()
    switch authStatus {
    case .authorized:
      transcribe(filePath: filePath, locale: locale, result: result)
    case .notDetermined:
      SFSpeechRecognizer.requestAuthorization { [weak self] status in
        DispatchQueue.main.async {
          guard status == .authorized else {
            result(
              FlutterError(
                code: "unavailable",
                message: "Transcription is not available on this device",
                details: nil
              )
            )
            return
          }
          self?.transcribe(filePath: filePath, locale: locale, result: result)
        }
      }
    default:
      result(
        FlutterError(
          code: "unavailable",
          message: "Transcription is not available on this device",
          details: nil
        )
      )
    }
  }

  private func transcribe(filePath: String, locale: String, result: @escaping FlutterResult) {
    let fileUrl = URL(fileURLWithPath: filePath)
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
    guard let recognizer, recognizer.isAvailable else {
      result(
        FlutterError(
          code: "unavailable",
          message: "Transcription is not available on this device",
          details: nil
        )
      )
      return
    }

    let request = SFSpeechURLRecognitionRequest(url: fileUrl)
    request.shouldReportPartialResults = false
    request.requiresOnDeviceRecognition = true

    recognizer.recognitionTask(with: request) { recognitionResult, error in
      if let error {
        result(
          FlutterError(
            code: "transcription_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
        return
      }
      guard let recognitionResult, recognitionResult.isFinal else {
        return
      }
      result(recognitionResult.bestTranscription.formattedString)
    }
  }
}
