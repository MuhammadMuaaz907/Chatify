import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { TEXT, IMAGE, UNKNOWN }

class ChatMessage {
  final String senderID;
  final MessageType type;
  final String content;
  final DateTime sentTime;

  ChatMessage({
    required this.senderID,
    required this.type,
    required this.content,
    required this.sentTime,
  });

  factory ChatMessage.fromJSON(Map<String, dynamic> _json) {
    MessageType _messaageType;
    switch (_json["type"]) {
      case "text":
        _messaageType = MessageType.TEXT;
        break;
      case "image":
        _messaageType = MessageType.IMAGE;
        break;
      default:
        _messaageType = MessageType.UNKNOWN;
    }

    return ChatMessage(
      senderID: _json["sender_id"],
      type: _messaageType,
      content: _json["content"],
      sentTime: _json["sent_time"].toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    String _messaageType;
    switch (type) {
      case MessageType.TEXT:
        _messaageType = "text";
        break;
      case MessageType.IMAGE:
        _messaageType = "image";
        break;
      default:
        _messaageType = "";
    }
    return {
      "content": content,
      "type": type,
      "sender_id": senderID,
      "sent_time": Timestamp.fromDate(sentTime),
    };
  }
}
