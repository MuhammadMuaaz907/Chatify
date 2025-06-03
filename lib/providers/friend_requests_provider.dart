import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/database_service.dart';
import '../models/chat_user.dart';
import '../providers/authentication_provider.dart';

class FriendRequestsProvider extends ChangeNotifier {
  late DatabaseService _database;
  late AuthenticationProvider _auth;

  FriendRequestsProvider(this._auth) {
    _database = GetIt.instance.get<DatabaseService>();
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      return await _database.getPendingFriendRequests(_auth.user.uid);
    } catch (e) {
      print("Error fetching friend requests: $e");
      return [];
    }
  }

  Future<ChatUser> getUser(String uid) async {
    DocumentSnapshot snapshot = await _database.getUser(uid);
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    data["uid"] = snapshot.id;
    return ChatUser.fromJSON(data);
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _database.acceptFriendRequest(requestId);
      notifyListeners();
    } catch (e) {
      print("Error accepting friend request: $e");
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _database.rejectFriendRequest(requestId);
      notifyListeners();
    } catch (e) {
      print("Error rejecting friend request: $e");
    }
  }

  void refresh() {
    notifyListeners(); // To refresh UI after unfriend
  }
}