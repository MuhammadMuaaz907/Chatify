import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../providers/authentication_provider.dart';
import '../models/chat_user.dart';
import '../models/chat_message.dart';
import '../models/chat.dart';
import '../pages/chat_page.dart';

class UsersPageProvider extends ChangeNotifier {
  AuthenticationProvider _auth;

  late DatabaseService _database;
  late NavigationService _navigation;

  List<ChatUser>? users;
  late List<ChatUser> _selectedUsers;
  Map<String, bool> _pendingRequests = {}; // Track pending requests

  List<ChatUser> get selectedUsers {
    return _selectedUsers;
  }

  UsersPageProvider(this._auth) {
    _selectedUsers = [];
    _database = GetIt.instance.get<DatabaseService>();
    _navigation = GetIt.instance.get<NavigationService>();
    getUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getUsers({String? name}) async {
    _selectedUsers = [];
    try {
      _database.getUsers(name: name).then((_snapshot) async {
        users = _snapshot.docs.map((_doc) {
          Map<String, dynamic> _data = _doc.data() as Map<String, dynamic>;
          _data["uid"] = _doc.id;
          return ChatUser.fromJSON(_data);
        }).toList();
        await _syncPendingRequests();
        notifyListeners();
      });
    } catch (e) {
      print("Error getting users.");
      print(e);
    }
  }

  Future<void> _syncPendingRequests() async {
    if (_auth.user == null || _auth.user?.uid.isEmpty == true) return;
    try {
      QuerySnapshot requestSnapshot = await _database
          .getFriendRequestsCollection()
          .where('senderId', isEqualTo: _auth.user!.uid)
          .where('status', isEqualTo: 'pending')
          .get();
      _pendingRequests.clear();
      for (var doc in requestSnapshot.docs) {
        _pendingRequests[doc.get('receiverId')] = true;
      }
      notifyListeners(); // Ensure UI updates after sync
    } catch (e) {
      print("Error syncing pending requests: $e");
    }
  }

  void updateSelectedUsers(ChatUser _user) {
    if (_selectedUsers.contains(_user)) {
      _selectedUsers.remove(_user);
    } else {
      _selectedUsers.add(_user);
    }
    notifyListeners();
  }

  Future<bool> sendFriendRequest(String receiverId) async {
    if (_auth.user == null || _auth.user?.uid.isEmpty == true) {
      print("User not authenticated.");
      _navigation.removeAndNavigateToRoute('/login');
      return false;
    }
    try {
      await _database.sendFriendRequest(_auth.user!.uid, receiverId);
      _pendingRequests[receiverId] = true;
      notifyListeners(); // Notify UI instantly
      return true;
    } catch (e) {
      print("Error sending friend request: $e");
      return false;
    }
  }

  Future<bool> isFriend(String userId) async {
    if (_auth.user == null) return false;
    List<String> friends = await _database.getFriends(_auth.user!.uid);
    return friends.contains(userId);
  }

  Future<bool> isRequestPending(String userId) async {
    bool isPendingLocally = _pendingRequests[userId] ?? false;
    if (isPendingLocally) {
      try {
        QuerySnapshot requestSnapshot = await _database
            .getFriendRequestsCollection()
            .where('senderId', isEqualTo: _auth.user!.uid)
            .where('receiverId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (requestSnapshot.docs.isEmpty) {
          _pendingRequests.remove(userId);
          notifyListeners(); // Update UI if pending status changes
          return false;
        }
        return true;
      } catch (e) {
        print("Error checking pending request: $e");
        return isPendingLocally;
      }
    }
    try {
      QuerySnapshot requestSnapshot = await _database
          .getFriendRequestsCollection()
          .where('senderId', isEqualTo: _auth.user!.uid)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      bool isPending = requestSnapshot.docs.isNotEmpty;
      if (isPending) _pendingRequests[userId] = true;
      notifyListeners(); // Update UI
      return isPending;
    } catch (e) {
      print("Error checking pending request: $e");
      return false;
    }
  }

  Future<bool> cancelFriendRequest(String receiverId) async {
    if (_auth.user == null || _auth.user?.uid.isEmpty == true) {
      print("User not authenticated.");
      _navigation.removeAndNavigateToRoute('/login');
      return false;
    }
    try {
      await _database.cancelFriendRequest(_auth.user!.uid, receiverId);
      _pendingRequests.remove(receiverId);
      notifyListeners(); // Notify UI instantly
      return true;
    } catch (e) {
      print("Error canceling friend request: $e");
      return false;
    }
  }

  Future<bool> canCreateChat() async {
    if (_auth.user == null) return false;
    if (_selectedUsers.isEmpty) return false;
    for (ChatUser user in _selectedUsers) {
      if (user.uid != _auth.user?.uid && !await isFriend(user.uid)) {
        return false;
      }
    }
    return true;
  }

  void startChatWithFriend(ChatUser friend) async {
    _selectedUsers = [friend];
    if (_auth.user == null) return;

    // Check for existing chat
    Stream<QuerySnapshot> chatStream = _database.getChatsForUser(_auth.user!.uid);
    QuerySnapshot? existingChats;
    await for (var snapshot in chatStream) {
      existingChats = snapshot;
      break; // Take the first snapshot
    }

    if (existingChats != null) {
      for (var doc in existingChats.docs) {
        Map<String, dynamic> _chatData = doc.data() as Map<String, dynamic>;
        List<String> existingMembers = List<String>.from(_chatData["members"]);
        List<String> newMembers = [friend.uid, _auth.user!.uid];
        existingMembers.sort();
        newMembers.sort();
        if (!_chatData["is_group"] && _areMembersEqual(existingMembers, newMembers)) {
          print("Existing chat found: ${doc.id}");
          // Use doc directly instead of getChat
          print("Chat document data: ${doc.data()}"); // Debug log
          Map<String, dynamic>? _chatData = doc.data() as Map<String, dynamic>?; // Nullable
          if (_chatData == null) {
            print("No data found for chat: ${doc.id}");
            await createChat(); // Fallback to create new chat
            return;
          }
          List<ChatUser> _members = [];
          for (var _uid in _chatData["members"]) {
            DocumentSnapshot _userSnapshot = await _database.getUser(_uid);
            Map<String, dynamic> _userData = _userSnapshot.data() as Map<String, dynamic>;
            _userData["uid"] = _userSnapshot.id;
            _members.add(ChatUser.fromJSON(_userData));
          }
          List<ChatMessage> _messages = [];
          QuerySnapshot _chatMessage = await _database.getLastMessageForChat(doc.id);
          if (_chatMessage.docs.isNotEmpty) {
            Map<String, dynamic> _messageData = _chatMessage.docs.first.data()! as Map<String, dynamic>;
            _messages.add(ChatMessage.fromJSON(_messageData));
          }
          Chat _existingChat = Chat(
            uid: doc.id,
            currentUserUid: _auth.user!.uid,
            members: _members,
            messages: _messages,
            activity: _chatData["is_activity"],
            group: _chatData["is_group"],
            groupName: _chatData["group_name"],
          );
          _selectedUsers = [];
          notifyListeners();
          _navigation.navigateToPage(ChatPage(chat: _existingChat));
          return;
        }
      }
    }

    // If no existing chat, create new one
    await createChat();
  }

  Future<void> createChat({String? groupName}) async {
    if (_auth.user == null) return;
    try {
      List<String> _membersIds = _selectedUsers.map((_user) => _user.uid).toList();
      _membersIds.add(_auth.user!.uid);
      bool _isGroup = _selectedUsers.length > 1;

      DocumentReference? _doc = await _database.createChat({
        "is_group": _isGroup,
        "is_activity": false,
        "members": _membersIds,
        "group_name": groupName,
      });
      List<ChatUser> _members = [];
      for (var _uid in _membersIds) {
        DocumentSnapshot _userSnapshot = await _database.getUser(_uid);
        Map<String, dynamic> _userData = _userSnapshot.data() as Map<String, dynamic>;
        _userData["uid"] = _userSnapshot.id;
        _members.add(ChatUser.fromJSON(_userData));
      }
      ChatPage _chatPage = ChatPage(
        chat: Chat(
          uid: _doc!.id,
          currentUserUid: _auth.user!.uid,
          members: _members,
          messages: [],
          activity: false,
          group: _isGroup,
          groupName: groupName,
        ),
      );
      _selectedUsers = [];
      notifyListeners();
      _navigation.navigateToPage(_chatPage);
    } catch (e) {
      print("Error creating chat: $e");
    }
  }

  // Helper method to compare member lists
  bool _areMembersEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    list1.sort();
    list2.sort();
    return list1.every((item) => list2.contains(item));
  }
}