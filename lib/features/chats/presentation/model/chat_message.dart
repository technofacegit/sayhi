class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime sentAt;
  final String type;
  final String mediaUrl;
  final int? mediaDurationSec;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.sentAt,
    this.type = 'text',
    this.mediaUrl = '',
    this.mediaDurationSec,
  });

  bool get isVideoNote => type == 'video_note' && mediaUrl.isNotEmpty;
}
