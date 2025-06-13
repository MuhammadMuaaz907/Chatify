import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../providers/authentication_provider.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import '../models/chat_user.dart';

class ChatsPageProvider extends ChangeNotifier {
  AuthenticationProvider _auth;

  late DatabaseService _db;

  List<Chat>? chats;

  late StreamSubscription _chatsStream;

  ChatsPageProvider(this._auth) {
    _db = GetIt.instance.get<DatabaseService>();
    getChats();
  }

  @override
  void dispose() {
    _chatsStream.cancel();
    super.dispose();
  }

  void getChats() async {
    try {
      if (_auth.user == null || _auth.user?.uid == null) return;
      _chatsStream = _db.getChatsForUser(_auth.user!.uid).listen((
        _snapshot,
      ) async {
        List<Chat> tempChats = await Future.wait(
          _snapshot.docs.map((_d) async {
            Map<String, dynamic> _chatData = _d.data() as Map<String, dynamic>;
            // Get Users in Chat
            List<ChatUser> _members = [];
            for (var _uid in _chatData["members"]) {
              DocumentSnapshot _userSnapshot = await _db.getUser(_uid);
              Map<String, dynamic> _userData =
                  _userSnapshot.data() as Map<String, dynamic>;
              _userData["uid"] = _userSnapshot.id;
              _members.add(ChatUser.fromJSON(_userData));
            }
            // Get last message for chat
            List<ChatMessage> _messages = [];
            QuerySnapshot _chatMessage = await _db.getLastMessageForChat(_d.id);
            if (_chatMessage.docs.isNotEmpty) {
              Map<String, dynamic> _messageData =
                  _chatMessage.docs.first.data()! as Map<String, dynamic>;
              ChatMessage _message = ChatMessage.fromJSON(_messageData);
              _messages.add(_message);
            }

            // Return Chat Instance
            return Chat(
              uid: _d.id,
              currentUserUid: _auth.user!.uid,
              members: _members,
              messages: _messages,
              activity: _chatData["is_activity"],
              group: _chatData["is_group"],
              groupName: _chatData["group_name"],
            );
          }).toList(),
        );

        // Sort chats by latest message sentTime (newest first)
        tempChats.sort((a, b) {
          DateTime? aSentTime = a.messages.isNotEmpty ? a.messages.first.sentTime : null;
          DateTime? bSentTime = b.messages.isNotEmpty ? b.messages.first.sentTime : null;
          if (aSentTime == null && bSentTime == null) return 0;
          if (aSentTime == null) return 1;
          if (bSentTime == null) return -1;
          return bSentTime.compareTo(aSentTime); // Newest first
        });

        // Filter unique chats based on members
        Map<String, Chat> uniqueChats = {};
        for (var chat in tempChats) {
          // Create a key based on sorted member UIDs (excluding current user for uniqueness)
          List<String> memberUids = chat.members
              .where((member) => member.uid != _auth.user!.uid)
              .map((member) => member.uid)
              .toList()
              ..sort();
          String key = memberUids.join(',');
          uniqueChats[key] = chat; // Keep the latest chat for this member set
        }
        chats = uniqueChats.values.toList();
        notifyListeners();
      });
    } catch (e) {
      print(e);
      print("Error getting chat");
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _db.deleteChat(chatId); // Assuming deleteChat method exists
      // Update local chats list (optional, stream will handle real-time update)
      if (chats != null) {
        chats!.removeWhere((chat) => chat.uid == chatId);
        notifyListeners();
      }
    } catch (e) {
      print("Error deleting chat: $e");
    }
  }
}