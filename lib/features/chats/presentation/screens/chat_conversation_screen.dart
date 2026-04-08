import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/camera_diagnostics.dart';
import 'package:qr_dating_app/core/camera_session_state.dart';
import 'package:qr_dating_app/core/camera_warmup_service.dart';
import 'package:qr_dating_app/core/perf_log.dart';
import 'package:qr_dating_app/features/chats/data/chat_messages_repository.dart';
import 'package:qr_dating_app/features/chats/presentation/model/chat_message.dart';
import 'package:qr_dating_app/features/chats/presentation/utils/chat_time_format.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:vibration/vibration.dart';
import 'package:video_player/video_player.dart';

class ChatConversationScreen extends StatefulWidget {
  final String chatId;

  const ChatConversationScreen({super.key, required this.chatId});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _composer = TextEditingController();
  final FocusNode _composerFocus = FocusNode();
  final ChatMessagesRepository _repo = ChatMessagesRepository();
  CameraController? _camera;
  Timer? _recordingTicker;
  Timer? _holdToRecordTimer;

  /// Global position where the video-note gesture started (for drag deltas).
  Offset? _videoNoteDragOriginGlobal;
  bool _recordButtonPressed = false;
  bool _abortVideoNoteStart = false;
  bool _recordPointerActive = false;

  ChatPartnerPreview? _partner;
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  bool _preparingCamera = false;
  bool _recordingVideoNote = false;
  bool _processingVideoNote = false;
  DateTime? _recordingStartedAt;
  Duration _recordingPausedTotal = Duration.zero;
  DateTime? _recordingPausedAt;
  bool _videoNoteWillCancel = false;
  bool _videoNoteLocked = false;
  bool _videoNotePaused = false;
  double _videoNoteDragDx = 0;
  double _videoNoteDragDy = 0;
  Object? _loadError;

  CameraSessionState _cameraSessionState = CameraSessionState.idle;
  bool _cameraSessionReady = false;

  void _syncCameraSession() {
    final s = CameraWarmupService.instance.sessionState.value;
    _cameraSessionState = s;
    _cameraSessionReady = s == CameraSessionState.ready;
    _camera = CameraWarmupService.instance.controller;
  }

  void _onCameraSessionChanged() {
    if (!mounted) return;
    setState(_syncCameraSession);
  }

  @override
  void initState() {
    super.initState();
    _composer.addListener(_onComposerChanged);
    _syncCameraSession();
    CameraWarmupService.instance.sessionState.addListener(
      _onCameraSessionChanged,
    );
    unawaited(CameraWarmupService.instance.beginChatSession());
    _load();
  }

  void _onComposerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    CameraWarmupService.instance.sessionState.removeListener(
      _onCameraSessionChanged,
    );
    unawaited(CameraWarmupService.instance.releaseChatSession());
    _recordingTicker?.cancel();
    _holdToRecordTimer?.cancel();
    _composer.removeListener(_onComposerChanged);
    _composer.dispose();
    _composerFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _repo.touchMyPresence();
      final partner = await _repo.fetchPartnerPreview(widget.chatId);
      final messages = await _repo.fetchMessages(widget.chatId);
      await _repo.markChatRead(widget.chatId);
      if (!mounted) return;
      setState(() {
        _partner = partner;
        _messages = messages;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd();
        Future<void>.delayed(const Duration(milliseconds: 80), () {
          if (mounted) _scrollToEnd();
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _triggerRecordHaptic({required bool isStart}) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        if (Platform.isIOS) {
          if (isStart) {
            await Vibration.vibrate(duration: 40, sharpness: 0.6);
          } else {
            await Vibration.vibrate(duration: 85, sharpness: 0.88);
          }
        } else {
          if (isStart) {
            await Vibration.vibrate(duration: 55);
          } else {
            await Vibration.vibrate(duration: 110);
          }
        }
        return;
      }
      if (Platform.isIOS) {
        if (isStart) {
          await HapticFeedback.vibrate();
          await HapticFeedback.lightImpact();
          await Future<void>.delayed(const Duration(milliseconds: 12));
          await HapticFeedback.mediumImpact();
        } else {
          await HapticFeedback.vibrate();
          await HapticFeedback.heavyImpact();
        }
      } else {
        if (isStart) {
          await HapticFeedback.selectionClick();
        } else {
          await HapticFeedback.vibrate();
        }
      }
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  Duration _recordingElapsed() {
    final start = _recordingStartedAt;
    if (start == null) return Duration.zero;
    if (_recordingPausedAt != null) {
      return _recordingPausedAt!.difference(start) - _recordingPausedTotal;
    }
    return DateTime.now().difference(start) - _recordingPausedTotal;
  }

  String _formatRecordingElapsedLabel() {
    final d = _recordingElapsed();
    final sec = d.inSeconds;
    final cs = (d.inMilliseconds % 1000) ~/ 10;
    return '${sec.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')} s';
  }

  void _resetRecordingClock() {
    _recordingStartedAt = null;
    _recordingPausedTotal = Duration.zero;
    _recordingPausedAt = null;
  }

  void _startRecordingTicker() {
    _recordingTicker?.cancel();
    _recordingTicker = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted || !_recordingVideoNote) {
        t.cancel();
        return;
      }
      if (_videoNotePaused) return;
      setState(() {});
      if (_recordingElapsed().inMilliseconds >= 60000) {
        _stopAndSendVideoNote();
      }
    });
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending || _partner == null) return;
    setState(() => _sending = true);
    try {
      final msg = await _repo.sendMessage(widget.chatId, text);
      await _repo.touchMyPresence();
      if (!mounted) return;
      if (msg != null) {
        setState(() {
          _messages = [..._messages, msg];
          _composer.clear();
          _sending = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      } else {
        setState(() => _sending = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  /// Lets the next frame paint (spinner / "Preparing camera") before heavy native work.
  Future<void> _yieldUiFrame() async {
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _ensureCameraReady(Stopwatch trace) async {
    if (_camera != null && _camera!.value.isInitialized) {
      perfLog('ChatVideoNote', 'camera already initialized', trace);
      return;
    }
    final seg = Stopwatch()..start();
    await CameraWarmupService.instance.ensureSessionReady();
    perfLog(
      'ChatVideoNote',
      'ensureSessionReady (init+prepare) ${seg.elapsedMilliseconds}ms',
      trace,
    );
    if (!mounted) return;
    _camera = CameraWarmupService.instance.controller;
    if (_camera == null || !_camera!.value.isInitialized) {
      throw Exception('No camera found');
    }
  }

  static const Duration _holdToRecordDelay = Duration(milliseconds: 200);

  void _onPointerUpBeforeRecordingStarts() {
    if (_recordingVideoNote) return;
    _recordPointerActive = false;
    _holdToRecordTimer?.cancel();
    _holdToRecordTimer = null;
    _abortVideoNoteStart = true;
    if (mounted) {
      setState(() {
        _recordButtonPressed = false;
        _preparingCamera = false;
      });
    }
  }

  void _onRecordButtonPointerDown(PointerDownEvent e) {
    if (_sending ||
        _recordingVideoNote ||
        _preparingCamera ||
        !_cameraSessionReady) {
      return;
    }
    _abortVideoNoteStart = false;
    _recordPointerActive = true;
    _videoNoteDragOriginGlobal = e.position;
    _holdToRecordTimer?.cancel();
    _holdToRecordTimer = Timer(_holdToRecordDelay, () {
      if (!mounted) return;
      _startVideoNote();
    });
    setState(() {
      _recordButtonPressed = true;
      _videoNoteDragDx = 0;
      _videoNoteDragDy = 0;
      _videoNoteWillCancel = false;
    });
  }

  void _onRecordButtonPointerMove(PointerMoveEvent e) {
    if (!_recordPointerActive) return;
    if (!_recordingVideoNote || _camera == null) return;
    if (_videoNoteLocked) return;
    final origin = _videoNoteDragOriginGlobal;
    if (origin == null) return;
    final dx = e.position.dx - origin.dx;
    final dy = e.position.dy - origin.dy;
    if (!mounted) return;
    setState(() {
      _videoNoteDragDx = dx;
      _videoNoteDragDy = dy;
      _videoNoteWillCancel = dx <= -84;
      if (dy <= -72) {
        _videoNoteLocked = true;
      }
    });
  }

  Future<void> _onRecordButtonPointerUp() async {
    _recordPointerActive = false;
    if (!_recordingVideoNote) return;
    if (_videoNoteLocked) return;
    if (_videoNoteWillCancel) {
      await _cancelVideoNote();
    } else {
      await _stopAndSendVideoNote();
    }
  }

  Future<void> _startVideoNote() async {
    if (_sending || _recordingVideoNote) return;
    _abortVideoNoteStart = false;
    if (!mounted) return;
    final trace = Stopwatch()..start();
    perfLog('ChatVideoNote', '_startVideoNote begin', trace);
    setState(() => _preparingCamera = true);
    try {
      final seg = Stopwatch()..start();
      await _yieldUiFrame();
      perfLog(
        'ChatVideoNote',
        '_yieldUiFrame (before ensure) ${seg.elapsedMilliseconds}ms',
        trace,
      );
      await _ensureCameraReady(trace);
      if (!mounted || _abortVideoNoteStart) {
        if (mounted) setState(() => _preparingCamera = false);
        return;
      }
      _camera = CameraWarmupService.instance.controller;
      seg
        ..reset()
        ..start();
      await _yieldUiFrame();
      perfLog(
        'ChatVideoNote',
        '_yieldUiFrame (before record) ${seg.elapsedMilliseconds}ms',
        trace,
      );
      seg
        ..reset()
        ..start();
      await _camera!.startVideoRecording();
      perfLog(
        'ChatVideoNote',
        'startVideoRecording ${seg.elapsedMilliseconds}ms',
        trace,
      );
      CameraWarmupService.instance.notifyRecordingStartCompleted(
        elapsedMs: seg.elapsedMilliseconds,
      );
      if (!mounted || _abortVideoNoteStart) {
        try {
          final sw = Stopwatch()..start();
          await _camera!.stopVideoRecording();
          final cfg = CameraWarmupService.instance.config;
          cameraDiag(
            'stopVideoRecording',
            elapsedMs: sw.elapsedMilliseconds,
            preset: cfg.resolutionPreset,
            enableAudio: cfg.enableAudio,
            extra: 'abort_after_start',
          );
        } catch (_) {}
        if (mounted) setState(() => _preparingCamera = false);
        return;
      }
      if (!mounted) return;
      setState(() {
        _recordingVideoNote = true;
        _preparingCamera = false;
        _recordButtonPressed = false;
        _recordingStartedAt = DateTime.now();
        _recordingPausedTotal = Duration.zero;
        _recordingPausedAt = null;
        _videoNoteWillCancel = false;
        _videoNoteLocked = false;
        _videoNotePaused = false;
        _videoNoteDragDx = 0;
        _videoNoteDragDy = 0;
      });
      _triggerRecordHaptic(isStart: true);
      _startRecordingTicker();
      perfLog('ChatVideoNote', 'recording UI shown', trace);
    } catch (e) {
      if (!mounted) return;
      setState(() => _preparingCamera = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _stopAndSendVideoNote() async {
    if (!_recordingVideoNote || _camera == null) return;
    final trace = Stopwatch()..start();
    perfLog('ChatVideoNote', '_stopAndSendVideoNote begin', trace);
    final elapsedForUpload = _recordingElapsed();
    final durationSec = (elapsedForUpload.inMilliseconds / 1000).round().clamp(
      1,
      60,
    );
    _recordingTicker?.cancel();
    _triggerRecordHaptic(isStart: false);
    setState(() {
      _recordingVideoNote = false;
      _sending = true;
      _processingVideoNote = true;
      _resetRecordingClock();
    });
    try {
      var seg = Stopwatch()..start();
      final file = await _camera!.stopVideoRecording();
      perfLog(
        'ChatVideoNote',
        'stopVideoRecording ${seg.elapsedMilliseconds}ms',
        trace,
      );
      final cfg = CameraWarmupService.instance.config;
      cameraDiag(
        'stopVideoRecording',
        elapsedMs: seg.elapsedMilliseconds,
        preset: cfg.resolutionPreset,
        enableAudio: cfg.enableAudio,
      );
      seg = Stopwatch()..start();
      final msg = await _repo.sendVideoNote(
        widget.chatId,
        filePath: file.path,
        durationSec: durationSec,
      );
      perfLog(
        'ChatVideoNote',
        'sendVideoNote (upload+RPC) ${seg.elapsedMilliseconds}ms',
        trace,
      );
      seg = Stopwatch()..start();
      await _repo.touchMyPresence();
      perfLog(
        'ChatVideoNote',
        'touchMyPresence ${seg.elapsedMilliseconds}ms',
        trace,
      );
      if (!mounted) return;
      if (msg != null) {
        setState(() {
          _messages = [..._messages, msg];
          _sending = false;
          _processingVideoNote = false;
          _videoNoteWillCancel = false;
          _videoNoteLocked = false;
          _videoNotePaused = false;
          _videoNoteDragDx = 0;
          _videoNoteDragDy = 0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
        perfLog(
          'ChatVideoNote',
          '_stopAndSendVideoNote success (message added)',
          trace,
        );
      } else {
        setState(() {
          _sending = false;
          _processingVideoNote = false;
        });
        perfLog(
          'ChatVideoNote',
          '_stopAndSendVideoNote done (msg null)',
          trace,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _processingVideoNote = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _cancelVideoNote() async {
    if (!_recordingVideoNote || _camera == null) return;
    _recordingTicker?.cancel();
    _triggerRecordHaptic(isStart: false);
    try {
      final seg = Stopwatch()..start();
      await _camera!.stopVideoRecording();
      final cfg = CameraWarmupService.instance.config;
      cameraDiag(
        'stopVideoRecording',
        elapsedMs: seg.elapsedMilliseconds,
        preset: cfg.resolutionPreset,
        enableAudio: cfg.enableAudio,
        extra: 'cancel',
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _recordingVideoNote = false;
      _resetRecordingClock();
      _videoNoteWillCancel = false;
      _videoNoteLocked = false;
      _videoNotePaused = false;
      _videoNoteDragDx = 0;
      _videoNoteDragDy = 0;
    });
  }

  Future<void> _togglePauseVideoNote() async {
    if (!_recordingVideoNote || !_videoNoteLocked || _camera == null) return;
    try {
      if (_videoNotePaused) {
        await _camera!.resumeVideoRecording();
        if (!mounted) return;
        setState(() {
          final p = _recordingPausedAt;
          if (p != null) {
            _recordingPausedTotal += DateTime.now().difference(p);
          }
          _recordingPausedAt = null;
          _videoNotePaused = false;
        });
      } else {
        await _camera!.pauseVideoRecording();
        if (!mounted) return;
        setState(() {
          _recordingPausedAt = DateTime.now();
          _videoNotePaused = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_loadError != null || _partner == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: Center(child: Text(l10n.chatNotFound)),
      );
    }

    final thread = _partner!;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () =>
              context.push(AppRouter.chatUserProfilePath(widget.chatId)),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.9),
                  backgroundImage: thread.avatarUrl.isEmpty
                      ? null
                      : NetworkImage(thread.avatarUrl),
                  child: thread.avatarUrl.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    thread.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: msg.isVideoNote
                            ? _VideoNoteBubble(message: msg)
                            : _MessageBubble(message: msg),
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_cameraSessionState == CameraSessionState.warmingUp ||
                          _cameraSessionState == CameraSessionState.idle)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.chatPreparingCameraSession,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_cameraSessionState == CameraSessionState.error)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            l10n.chatCameraUnavailable,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _composer,
                              focusNode: _composerFocus,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: l10n.chatMessageHint,
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_composer.text.trim().isNotEmpty)
                            IconButton.filled(
                              onPressed: _sending ? null : _send,
                              icon: _sending
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 22),
                            )
                          else
                            Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (_sending || !_cameraSessionReady)
                                  ? null
                                  : _onRecordButtonPointerDown,
                              onPointerMove: (_sending || !_cameraSessionReady)
                                  ? null
                                  : _onRecordButtonPointerMove,
                              onPointerUp: (_sending || !_cameraSessionReady)
                                  ? null
                                  : (_) async {
                                      if (_recordingVideoNote) {
                                        await _onRecordButtonPointerUp();
                                        return;
                                      }
                                      _onPointerUpBeforeRecordingStarts();
                                    },
                              onPointerCancel:
                                  (_sending || !_cameraSessionReady)
                                  ? null
                                  : (_) async {
                                      if (_recordingVideoNote) {
                                        await _onRecordButtonPointerUp();
                                        return;
                                      }
                                      _onPointerUpBeforeRecordingStarts();
                                    },
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 120),
                                opacity:
                                    _cameraSessionReady || _recordingVideoNote
                                    ? 1
                                    : 0.42,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  width: 48,
                                  height: 48,
                                  transform: Matrix4.translationValues(
                                    _recordingVideoNote
                                        ? (_videoNoteDragDx < 0
                                              ? _videoNoteDragDx.clamp(
                                                  -48.0,
                                                  0.0,
                                                )
                                              : 0)
                                        : 0,
                                    _recordingVideoNote
                                        ? (_videoNoteDragDy < 0
                                              ? _videoNoteDragDy.clamp(
                                                  -18.0,
                                                  0.0,
                                                )
                                              : 0)
                                        : 0,
                                    0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _recordingVideoNote
                                        ? Colors.red
                                        : colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: _recordingVideoNote
                                        ? [
                                            BoxShadow(
                                              color: Colors.red.withValues(
                                                alpha: 0.32,
                                              ),
                                              blurRadius: 14,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : (_recordButtonPressed
                                              ? [
                                                  BoxShadow(
                                                    color: colorScheme.primary
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                    blurRadius: 10,
                                                    spreadRadius: 0,
                                                  ),
                                                ]
                                              : null),
                                  ),
                                  alignment: Alignment.center,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 100),
                                    scale:
                                        _recordButtonPressed &&
                                            !_recordingVideoNote
                                        ? 0.92
                                        : 1,
                                    child: Icon(
                                      _recordingVideoNote
                                          ? Icons.mic_rounded
                                          : Icons.videocam_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_recordingVideoNote &&
              _camera != null &&
              _camera!.value.isInitialized)
            Positioned.fill(
              child: Stack(
                children: [
                  Container(color: Colors.black.withValues(alpha: 0.94)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 300,
                            height: 300,
                            child: Stack(
                              children: [
                                ClipOval(
                                  child: SizedBox.expand(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width:
                                            _camera!
                                                .value
                                                .previewSize
                                                ?.height ??
                                            300,
                                        height:
                                            _camera!.value.previewSize?.width ??
                                            300,
                                        child: CameraPreview(_camera!),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.fiber_manual_record_rounded,
                                          color: Colors.redAccent,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatRecordingElapsedLabel(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (_videoNoteLocked) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.lock_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                onPressed: _cancelVideoNote,
                                icon: const Icon(Icons.close_rounded),
                              ),
                              if (_videoNoteLocked) ...[
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: _togglePauseVideoNote,
                                  icon: Icon(
                                    _videoNotePaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: _stopAndSendVideoNote,
                                  icon: const Icon(Icons.send_rounded),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: SafeArea(
                      top: false,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: _videoNoteWillCancel ? 1 : 0.9,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _videoNoteWillCancel
                                  ? Colors.red.withValues(alpha: 0.82)
                                  : Colors.black45,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.swipe_left_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _videoNoteLocked
                                      ? (_videoNotePaused
                                            ? 'Recording paused'
                                            : 'Recording locked')
                                      : _videoNoteWillCancel
                                      ? 'Release to cancel'
                                      : 'Slide left to cancel · Slide up to lock',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_preparingCamera && !_recordingVideoNote)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerUp: (_) => _onPointerUpBeforeRecordingStarts(),
                onPointerCancel: (_) => _onPointerUpBeforeRecordingStarts(),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.chatPreparingCameraSession,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (!CameraWarmupService
                                    .instance
                                    .hasSuccessfulRecordingStart)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      l10n.chatCameraFirstRecordingHint,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_processingVideoNote)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Sending video...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoNoteBubble extends StatefulWidget {
  const _VideoNoteBubble({required this.message});

  final ChatMessage message;

  @override
  State<_VideoNoteBubble> createState() => _VideoNoteBubbleState();
}

class _VideoNoteBubbleState extends State<_VideoNoteBubble> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.message.mediaUrl),
    );
    _controller = c;
    await c.initialize();
    c.setLooping(false);
    c.addListener(_onVideoTick);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onVideoTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final nowPlaying = c.value.isPlaying;
    if (nowPlaying != _isPlaying && mounted) {
      setState(() => _isPlaying = nowPlaying);
    }
    final ended =
        !c.value.isPlaying &&
        c.value.position >= c.value.duration &&
        c.value.duration > Duration.zero;
    if (ended) {
      c.seekTo(Duration.zero);
      if (mounted && _isPlaying) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isMe;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final baseSize = 170.0;
    final expandedSize = (screenWidth - 24).clamp(220.0, 520.0);
    final circleSize = _isPlaying ? expandedSize : baseSize;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              final c = _controller;
              if (c == null || !c.value.isInitialized) return;
              if (c.value.isPlaying) {
                c.pause();
              } else {
                if (c.value.position >= c.value.duration &&
                    c.value.duration > Duration.zero) {
                  c.seekTo(Duration.zero);
                }
                c.play();
              }
              setState(() {});
            },
            child: ClipOval(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: circleSize,
                height: circleSize,
                child:
                    _loading ||
                        _controller == null ||
                        !_controller!.value.isInitialized
                    ? const ColoredBox(
                        color: Colors.black12,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _controller!.value.size.width,
                              height: _controller!.value.size.height,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                          if (!_controller!.value.isPlaying)
                            const Center(
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                size: 52,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMessageTime(widget.message.sentAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bubble = message.isMe
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.95);
    final onBubble = message.isMe
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(message.isMe ? 18 : 4),
              bottomRight: Radius.circular(message.isMe ? 4 : 18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: message.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: onBubble,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMessageTime(message.sentAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onBubble.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
