import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

const String USER_COLLECTION = "Users";
const String CHAT_COLLECTION = "Chats";
const String MESSAGES_COLLECTION = "messages";
const String FRIEND_REQUESTS_COLLECTION = "FriendRequests";

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseService() {}

  Future<void> createUser(
    String _uid,
    String _email,
    String _name,
    String _ImageURL,
  ) async {
    try {
      await _db.collection(USER_COLLECTION).doc(_uid).set({
        "email": _email,
        "image": _ImageURL,
        "lastActive": DateTime.now().toUtc(),
        "name": _name,
        "friends": [],
      });
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<DocumentSnapshot> getUser(String _uid) {
    return _db.collection(USER_COLLECTION).doc(_uid).get();
  }

  Future<QuerySnapshot> getUsers({String? name}) {
    Query _query = _db.collection(USER_COLLECTION);
    if (name != null) {
      _query = _query
          .where("name", isGreaterThanOrEqualTo: name)
          .where("name", isLessThanOrEqualTo: name + "z");
    }
    return _query.get();
  }

  Stream<QuerySnapshot> getChatsForUser(String _uid) {
    return _db
        .collection(CHAT_COLLECTION)
        .where('members', arrayContains: _uid)
        .snapshots();
  }

  Future<QuerySnapshot> getLastMessageForChat(String _chatID) {
    return _db
        .collection(CHAT_COLLECTION)
        .doc(_chatID)
        .collection(MESSAGES_COLLECTION)
        .orderBy("sent_time", descending: true)
        .limit(1)
        .get();
  }

  Stream<QuerySnapshot> streamMessagesForChat(String _chatID) {
    return _db
        .collection(CHAT_COLLECTION)
        .doc(_chatID)
        .collection(MESSAGES_COLLECTION)
        .orderBy("sent_time", descending: false)
        .snapshots();
  }

  Future<void> addMessageToChat(String _chatID, ChatMessage _message) async {
    try {
      await _db
          .collection(CHAT_COLLECTION)
          .doc(_chatID)
          .collection(MESSAGES_COLLECTION)
          .add(_message.toJson());
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> UpdateChatData(
    String _chatID,
    Map<String, dynamic> _data,
  ) async {
    try {
      await _db.collection(CHAT_COLLECTION).doc(_chatID).update(_data);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> updateUserLastSeenTime(String _uid) async {
    try {
      await _db.collection(USER_COLLECTION).doc(_uid).update({
        "lastActive": DateTime.now().toUtc(),
      });
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> deleteChat(String _chatID) async {
    try {
      await _db.collection(CHAT_COLLECTION).doc(_chatID).delete();
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<DocumentReference?> createChat(Map<String, dynamic> _data) async {
    try {
      DocumentReference _chat =
          await _db.collection(CHAT_COLLECTION).add(_data);
      return _chat;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    try {
      await _db.collection(FRIEND_REQUESTS_COLLECTION).add({
        "senderId": senderId,
        "receiverId": receiverId,
        "status": "pending",
        "timestamp": DateTime.now().toUtc(),
      });
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      DocumentSnapshot requestSnapshot = await _db
          .collection(FRIEND_REQUESTS_COLLECTION)
          .doc(requestId)
          .get();
      Map<String, dynamic> requestData =
          requestSnapshot.data() as Map<String, dynamic>;
      String senderId = requestData["senderId"];
      String receiverId = requestData["receiverId"];

      await _db.collection(USER_COLLECTION).doc(senderId).update({
        "friends": FieldValue.arrayUnion([receiverId]),
      });
      await _db.collection(USER_COLLECTION).doc(receiverId).update({
        "friends": FieldValue.arrayUnion([senderId]),
      });
      await _db.collection(FRIEND_REQUESTS_COLLECTION).doc(requestId).delete();
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _db.collection(FRIEND_REQUESTS_COLLECTION).doc(requestId).delete();
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingFriendRequests(
      String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection(FRIEND_REQUESTS_COLLECTION)
          .where("receiverId", isEqualTo: userId)
          .where("status", isEqualTo: "pending")
          .get();
      return snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "senderId": doc.get("senderId"),
          "receiverId": doc.get("receiverId"),
          "status": doc.get("status"),
          "timestamp": doc.get("timestamp"),
        };
      }).toList();
    } catch (e) {
      print("Error fetching friend requests: $e");
      return [];
    }
  }

  Future<List<String>> getFriends(String uid) async {
    try {
      DocumentSnapshot userSnapshot =
          await _db.collection(USER_COLLECTION).doc(uid).get();
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      return List<String>.from(userData["friends"] ?? []);
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<void> cancelFriendRequest(String senderId, String receiverId) async {
    try {
      QuerySnapshot requestSnapshot = await _db
          .collection(FRIEND_REQUESTS_COLLECTION)
          .where("senderId", isEqualTo: senderId)
          .where("receiverId", isEqualTo: receiverId)
          .where("status", isEqualTo: "pending")
          .limit(1)
          .get();

      if (requestSnapshot.docs.isNotEmpty) {
        await _db
            .collection(FRIEND_REQUESTS_COLLECTION)
            .doc(requestSnapshot.docs.first.id)
            .delete();
      } else {
        throw Exception("No pending friend request found to cancel.");
      }
    } catch (e) {
      print("Error canceling friend request: $e");
      throw e;
    }
  }

  Future<void> unfriendUser(String currentUserId, String friendId) async {
    try {
      // Remove each user from the other's friends list
      await _db.collection(USER_COLLECTION).doc(currentUserId).update({
        "friends": FieldValue.arrayRemove([friendId]),
      });
      await _db.collection(USER_COLLECTION).doc(friendId).update({
        "friends": FieldValue.arrayRemove([currentUserId]),
      });

      // Fetch chats where currentUserId is a member
      QuerySnapshot chatSnapshot = await _db
          .collection(CHAT_COLLECTION)
          .where('members', arrayContains: currentUserId)
          .where('is_group', isEqualTo: false)
          .get();

      // Filter chats in Dart to find those that also contain friendId
      for (var doc in chatSnapshot.docs) {
        List<String> members = List<String>.from(doc.get('members'));
        if (members.length == 2 && members.contains(friendId)) { // Ensure it's a one-on-one chat with friendId
          await deleteChat(doc.id);
        }
      }

      // Clean up any pending friend requests between these users
      QuerySnapshot requestSnapshot = await _db
          .collection(FRIEND_REQUESTS_COLLECTION)
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: friendId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestSnapshot.docs) {
        await _db.collection(FRIEND_REQUESTS_COLLECTION).doc(doc.id).delete();
      }

      // Also check for requests in the opposite direction
      requestSnapshot = await _db
          .collection(FRIEND_REQUESTS_COLLECTION)
          .where('senderId', isEqualTo: friendId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestSnapshot.docs) {
        await _db.collection(FRIEND_REQUESTS_COLLECTION).doc(doc.id).delete();
      }
    } catch (e) {
      print("Error unfriending user: $e");
      throw e;
    }
  }

  CollectionReference getFriendRequestsCollection() {
    return _db.collection(FRIEND_REQUESTS_COLLECTION);
  }
}