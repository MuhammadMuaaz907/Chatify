//package
import 'package:chatify_app/models/chat_user.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

//Services
import '../services/database_service.dart';
import '../services/navigation_service.dart';

//Models
import '../models/chat_user.dart';

class AuthenticationProvider extends ChangeNotifier {
  late final FirebaseAuth _auth;
  late final NavigationService _navigationService;
  late final DatabaseService _databaseService;

  late ChatUser user;

  AuthenticationProvider() {
    _auth = FirebaseAuth.instance;
    _navigationService = GetIt.instance.get<NavigationService>();
    _databaseService = GetIt.instance.get<DatabaseService>();

    _auth.authStateChanges().listen((_user) {
      if (_user != null) {
        _databaseService.updateUserLastSeenTime(_user.uid);
        _databaseService.getUser(_user.uid).then((_snapshot) {
          if (_snapshot.exists && _snapshot.data() != null) {
            Map<String, dynamic> _userData = _snapshot.data()! as Map<String, dynamic>;
            
            print("User JSON: $_userData"); // Debugging
            
            user = ChatUser.fromJSON({
              "uid": _user.uid,
              "name": _userData["name"] ?? "Guest",
              "email": _userData["email"] ?? "",
              "last_active": _userData["last_active"],
              "image": _userData["image"] ?? "",
            });
            _navigationService.removeAndNavigateToRoute('/home');
          } else {
            print("User data is null or doesn't exist");
            _navigationService.removeAndNavigateToRoute('/login');
          }
        }).catchError((error) {
          print("Error fetching user data: $error");
        });
      } else {
        _navigationService.removeAndNavigateToRoute('/login');
      }
    });
    print(FirebaseAuth.instance.currentUser?.uid);
  }

  Future<void> loginUsingEmailAndPassword(
    String _email,
    String _password,
  ) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );
    } on FirebaseAuthException {
      print("Error logging user into Firebase");
    } catch (e) {
      print(e);
    }
  }

  Future<String?> registerUserUsingEmailAndPassword(
    String _email,
    String _password,
  ) async {
    try {
      UserCredential _credentials = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      return _credentials.user!.uid;
    } on FirebaseAuthException {
      print("Error registering user into Firebase");
    } catch (e) {
      print(e);
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e);
    }
  }
}
