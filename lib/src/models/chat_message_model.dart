import 'ai_assistant_models.dart';

enum MessageSender {
  user,
  assistant,
}

class ChatMessageModel {
  ChatMessageModel({
    required this.id,
    required this.sender,
    required this.text,
    this.actionType = AiActionType.ask,
    this.citations = const <String>[],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final MessageSender sender;
  final String text;
  final AiActionType actionType;
  final List<String> citations;
  final DateTime timestamp;

  bool get isFromUser => sender == MessageSender.user;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.name,
      'text': text,
      'actionType': actionType.name,
      'citations': citations,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      sender: MessageSender.values.byName(json['sender'] as String),
      text: json['text'] as String,
      actionType: json['actionType'] == null
          ? AiActionType.ask
          : AiActionType.values.byName(json['actionType'] as String),
      citations: List<String>.from(json['citations'] as List? ?? const <String>[]),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
