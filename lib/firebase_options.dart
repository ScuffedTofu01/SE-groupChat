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
    apiKey: 'AIzaSyAhTs0ewU4XC3cqFWistRCM73BiDHIVBjk',
    appId: '1:559899415472:web:5904142c04beeffe963c75',
    messagingSenderId: '559899415472',
    projectId: 'chatapp-e4f45',
    authDomain: 'chatapp-e4f45.firebaseapp.com',
    storageBucket: 'chatapp-e4f45.firebasestorage.app',
    measurementId: 'G-3QJJ741Q0N',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQp6d97NI4brejd5mCz2mj0SI4jWc35k4',
    appId: '1:559899415472:android:6f842f104be84b6d963c75',
    messagingSenderId: '559899415472',
    projectId: 'chatapp-e4f45',
    storageBucket: 'chatapp-e4f45.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDaEy3tiy3eu-a9g_1yBGjpsG_mEgqYfLE',
    appId: '1:559899415472:ios:b4d3943e6ab3c506963c75',
    messagingSenderId: '559899415472',
    projectId: 'chatapp-e4f45',
    storageBucket: 'chatapp-e4f45.firebasestorage.app',
    iosBundleId: 'com.SE.groupapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDaEy3tiy3eu-a9g_1yBGjpsG_mEgqYfLE',
    appId: '1:559899415472:ios:2f4e83e13c37d4b3963c75',
    messagingSenderId: '559899415472',
    projectId: 'chatapp-e4f45',
    storageBucket: 'chatapp-e4f45.firebasestorage.app',
    iosBundleId: 'com.example.groupapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAhTs0ewU4XC3cqFWistRCM73BiDHIVBjk',
    appId: '1:559899415472:web:4fe2f2bb5078f16f963c75',
    messagingSenderId: '559899415472',
    projectId: 'chatapp-e4f45',
    authDomain: 'chatapp-e4f45.firebaseapp.com',
    storageBucket: 'chatapp-e4f45.firebasestorage.app',
    measurementId: 'G-5MP8DMKWTV',
  );

}