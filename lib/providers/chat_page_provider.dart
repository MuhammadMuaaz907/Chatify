import 'dart:async';

//Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';

//Services
import '../services/database_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/media_service.dart';
import '../services/navigation_service.dart';

//Providers
import '../providers/authentication_provider.dart';

//Models
import '../models/chat_message.dart';

const String CHAT_COLLECTION = "Chats";

class ChatPageProvider extends ChangeNotifier {
  late DatabaseService _db;
  late CloudStorageService _storage;
  late MediaService _media;
  late NavigationService _navigation;

  AuthenticationProvider _auth;
  ScrollController _messagesListViewController;

  String _chatId;
  List<ChatMessage>? messages;

  late StreamSubscription _messagesStream;
  late StreamSubscription _keyboardVisibilityStream;
  late KeyboardVisibilityController _keyboardVisibilityController;

  String? _message;

  String get message {
    return _message ?? "";
  }

  void set message(String _value) {
    _message = _value;
    notifyListeners();
  }

  ChatPageProvider(this._chatId, this._auth, this._messagesListViewController) {
    _db = GetIt.instance.get<DatabaseService>();
    _storage = GetIt.instance.get<CloudStorageService>();
    _media = GetIt.instance.get<MediaService>();
    _navigation = GetIt.instance.get<NavigationService>();
    _keyboardVisibilityController = KeyboardVisibilityController();
    initializeChat();
  }

  @override
  void dispose() {
    _messagesStream.cancel();
    _keyboardVisibilityStream.cancel();
    super.dispose();
  }

  Future<void> initializeChat() async {
    DocumentSnapshot chatSnapshot = await FirebaseFirestore.instance.collection(CHAT_COLLECTION).doc(_chatId).get();
    if (!chatSnapshot.exists) {
      _navigation.goBack();
      return;
    }
    Map<String, dynamic> chatData = chatSnapshot.data() as Map<String, dynamic>;
    List<String> members = List<String>.from(chatData["members"]);
    List<String> userFriends = await _db.getFriends(_auth.user.uid);
    for (String memberId in members) {
      if (memberId != _auth.user.uid && !userFriends.contains(memberId)) {
        _navigation.goBack();
        ScaffoldMessenger.of(NavigationService.navigatorkey.currentContext!).showSnackBar(
          SnackBar(content: Text("You can only chat with friends!")),
        );
        return;
      }
    }
    listenToMessages();
    listenToKeyboardChanges();
  }

  void listenToMessages() {
    try {
      _messagesStream = _db.streamMessagesForChat(_chatId).listen((_snapshot) {
        List<ChatMessage> _messages =
            _snapshot.docs.map((_m) {
              Map<String, dynamic> _messageData =
                  _m.data() as Map<String, dynamic>;
              return ChatMessage.fromJSON(_messageData);
            }).toList();
        messages = _messages;
        notifyListeners();
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          if (_messagesListViewController.hasClients) {
            _messagesListViewController.jumpTo(
              _messagesListViewController.position.maxScrollExtent,
            );
          }
        });
      });
    } catch (e) {
      print("Error Getting Messages");
      print(e);
    }
  }

  void listenToKeyboardChanges() {
    _keyboardVisibilityStream = _keyboardVisibilityController.onChange.listen((
      _event,
    ) {
      _db.UpdateChatData(_chatId, {"is_activity": _event});
    });
  }

  void sendTextMessage() {
    if (_message != null && _message!.isNotEmpty) {
      ChatMessage _messageToSend = ChatMessage(
        content: _message!,
        type: MessageType.TEXT,
        senderID: _auth.user.uid,
        sentTime: DateTime.now(),
      );
      _db.addMessageToChat(_chatId, _messageToSend);
      _message = null;
      notifyListeners();
    }
  }

  void sendImageMessage() async {
    try {
      PlatformFile? _file = await _media.pickImageFromLibrary();
      if (_file != null) {
        String? _downloadURL = await _storage.SavedChatImageToStorage(
          _chatId,
          _auth.user.uid,
          _file,
        );
        ChatMessage _messageToSend = ChatMessage(
          content: _downloadURL!,
          type: MessageType.IMAGE,
          senderID: _auth.user.uid,
          sentTime: DateTime.now(),
        );
        _db.addMessageToChat(_chatId, _messageToSend);
      }
    } catch (e) {
      print("Error sending Image Message");
      print(e);
    }
  }

  Future<bool> unfriendUser(String friendId) async {
    try {
      await _db.unfriendUser(_auth.user.uid, friendId);
      goBack(); // Redirect after unfriending
      return true;
    } catch (e) {
      print("Error unfriending user: $e");
      return false;
    }
  }

  void deleteChat() {
    goBack();
    _db.deleteChat(_chatId);
  }

  void goBack() {
    _navigation.goBack();
  }
}