import 'package:cloud_firestore/cloud_firestore.dart';

const String USER_COLLECTION = "Users";
const String CHAT_COLLECTION = "Chats";
const String MESSAGES_COLLECTION = "messages";

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
      });
    } catch (e) {
      print(e);
    }
  }

  Future<DocumentSnapshot> getUser(String _uid) {
    return _db.collection(USER_COLLECTION).doc(_uid).get();
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

  Future<void> updateUserLastSeenTime(String _uid) async {
    try {
      await _db.collection(USER_COLLECTION).doc(_uid).update({
        "lastActive": DateTime.now().toUtc(),
      });
    } catch (e) {
      print(e);
    }
  }
}
