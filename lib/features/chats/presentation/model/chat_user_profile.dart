class ChatUserProfile {
  final String chatId;
  final String name;
  final List<String> photoUrls;
  final String description;

  const ChatUserProfile({
    required this.chatId,
    required this.name,
    required this.photoUrls,
    required this.description,
  }) : assert(photoUrls.length == 4);
}
