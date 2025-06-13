import '../models/chat_message.dart';
import '../models/chat_user.dart';

class Chat {
  final String uid;
  final String currentUserUid;
  final bool activity;
  final bool group;
  final List<ChatUser> members;
  List<ChatMessage> messages;
  final String? groupName; // Added for group chat name

  late final List<ChatUser> _recepients;

  Chat({
    required this.uid,
    required this.currentUserUid,
    required this.members,
    required this.messages,
    required this.activity,
    required this.group,
    this.groupName,
  }) {
    _recepients = members.where((_i) => _i.uid != currentUserUid).toList();
  }

  List<ChatUser> recepients() {
    return _recepients;
  }

  String title() {
    if (group && groupName != null && groupName!.isNotEmpty) {
      return groupName!; // Return group name if it's a group chat with a set name
    }
    // Fallback for group chats without a name or non-group chats
    return !group
        ? (_recepients.isNotEmpty ? _recepients.first.name : "Unknown")
        : _recepients.map((_user) => _user.name).join(", ");
  }

}