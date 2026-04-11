class ChatMessage {
  final String id, senderId, senderName, text;
  final int ts;

  ChatMessage({required this.id, required this.senderId,
    required this.senderName, required this.text, required this.ts});

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] ?? '', senderId: j['senderId'] ?? '',
    senderName: j['senderName'] ?? '', text: j['text'] ?? '',
    ts: j['ts'] ?? 0,
  );
}