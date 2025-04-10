// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDY8n0CBGw6RaoU_dZ6cdHPr5Yqg8VKIgQ',
    appId: '1:442250265259:web:8bdafe7a1b0b929cebadee',
    messagingSenderId: '442250265259',
    projectId: 'chatifyapp-801bc',
    authDomain: 'chatifyapp-801bc.firebaseapp.com',
    storageBucket: 'chatifyapp-801bc.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB4YERtV_uRNnrRz3xnjl8g84i93L9Dhj4',
    appId: '1:442250265259:android:6cb1ccc322a46d88ebadee',
    messagingSenderId: '442250265259',
    projectId: 'chatifyapp-801bc',
    storageBucket: 'chatifyapp-801bc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCw9mMG-F6cqJ9lZHKxJVV3V3Vp86k2QgM',
    appId: '1:442250265259:ios:2aafdcbdb5fefc7aebadee',
    messagingSenderId: '442250265259',
    projectId: 'chatifyapp-801bc',
    storageBucket: 'chatifyapp-801bc.firebasestorage.app',
    iosBundleId: 'com.example.chatifyApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCw9mMG-F6cqJ9lZHKxJVV3V3Vp86k2QgM',
    appId: '1:442250265259:ios:2aafdcbdb5fefc7aebadee',
    messagingSenderId: '442250265259',
    projectId: 'chatifyapp-801bc',
    storageBucket: 'chatifyapp-801bc.firebasestorage.app',
    iosBundleId: 'com.example.chatifyApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDY8n0CBGw6RaoU_dZ6cdHPr5Yqg8VKIgQ',
    appId: '1:442250265259:web:554035a9674804dbebadee',
    messagingSenderId: '442250265259',
    projectId: 'chatifyapp-801bc',
    authDomain: 'chatifyapp-801bc.firebaseapp.com',
    storageBucket: 'chatifyapp-801bc.firebasestorage.app',
  );
}
