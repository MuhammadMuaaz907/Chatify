import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../services/database_service.dart';
import '../services/navigation_service.dart';
import '../providers/authentication_provider.dart';
import '../models/chat_user.dart';
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
      _database.getUsers(name: name).then((_snapshot) {
        users = _snapshot.docs.map((_doc) {
          Map<String, dynamic> _data = _doc.data() as Map<String, dynamic>;
          _data["uid"] = _doc.id;
          return ChatUser.fromJSON(_data);
        }).toList();
        notifyListeners();
      });
    } catch (e) {
      print("Error getting users.");
      print(e);
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
    if (_auth.user == null || _auth.user.uid.isEmpty) {
      print("User not authenticated.");
      _navigation.removeAndNavigateToRoute('/login');
      return false;
    }
    try {
      await _database.sendFriendRequest(_auth.user.uid, receiverId);
      _pendingRequests[receiverId] = true; // Mark as pending
      notifyListeners();
      return true;
    } catch (e) {
      print("Error sending friend request: $e");
      return false;
    }
  }

  Future<bool> isFriend(String userId) async {
    List<String> friends = await _database.getFriends(_auth.user.uid);
    return friends.contains(userId);
  }

  Future<bool> isRequestPending(String userId) async {
    bool isPendingLocally = _pendingRequests[userId] ?? false;
    if (isPendingLocally) {
      // Verify with Firestore
      try {
        QuerySnapshot requestSnapshot = await _database
            .getFriendRequestsCollection()
            .where('senderId', isEqualTo: _auth.user.uid)
            .where('receiverId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (requestSnapshot.docs.isEmpty) {
          _pendingRequests.remove(userId); // Sync local state
          notifyListeners();
          return false;
        }
        return true;
      } catch (e) {
        print("Error checking pending request: $e");
        return isPendingLocally; // Fallback to local state
      }
    }
    return false;
  }

  Future<bool> cancelFriendRequest(String receiverId) async {
    if (_auth.user == null || _auth.user.uid.isEmpty) {
      print("User not authenticated.");
      _navigation.removeAndNavigateToRoute('/login');
      return false;
    }
    try {
      await _database.cancelFriendRequest(_auth.user.uid, receiverId);
      _pendingRequests.remove(receiverId); // Remove from pending list
      notifyListeners();
      return true;
    } catch (e) {
      print("Error canceling friend request: $e");
      return false;
    }
  }

  Future<bool> canCreateChat() async {
    if (_selectedUsers.isEmpty) return false;
    for (ChatUser user in _selectedUsers) {
      if (user.uid != _auth.user.uid && !await isFriend(user.uid)) {
        return false;
      }
    }
    return true;
  }

  void startChatWithFriend(ChatUser friend) async {
    _selectedUsers = [friend]; // Sirf ek user ke saath chat start karna hai
    await createChat();
  }

  Future<void> createChat({String? groupName}) async {
    try {
      List<String> _membersIds =
          _selectedUsers.map((_user) => _user.uid).toList();
      _membersIds.add(_auth.user.uid);
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
        Map<String, dynamic> _userData =
            _userSnapshot.data() as Map<String, dynamic>;
        _userData["uid"] = _userSnapshot.id;
        _members.add(ChatUser.fromJSON(_userData));
      }
      ChatPage _chatPage = ChatPage(
        chat: Chat(
          uid: _doc!.id,
          currentUserUid: _auth.user.uid,
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
}