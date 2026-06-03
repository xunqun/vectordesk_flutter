// File: lib/src/vectordesk_firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase generated configuration
class VectorDeskFirebaseOptions {
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
        // Fallback to iOS configuration as it shares similar Firebase configurations for Apple platform.
        return ios;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqY6yCTAGQJcqeKN1OftMhZiBCOq6JYEQ',
    appId: '1:334271256568:web:5f0c4d0e2c7680c420280d',
    messagingSenderId: '334271256568',
    projectId: 'vectordesk-b445c',
    authDomain: 'vectordesk-b445c.firebaseapp.com',
    storageBucket: 'vectordesk-b445c.firebasestorage.app',
    measurementId: 'G-S14ZBH41ES',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPEyukDHkJThzcNwt4C6Mro4Bva4HEBGc',
    appId: '1:334271256568:android:6367f6c4f836bfbf20280d',
    messagingSenderId: '334271256568',
    projectId: 'vectordesk-b445c',
    storageBucket: 'vectordesk-b445c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDFZmuel7MMzKzgk9PRoy7K4bqyl5BZSYY',
    appId: '1:334271256568:ios:e9d5fadfe638ca2920280d',
    messagingSenderId: '334271256568',
    projectId: 'vectordesk-b445c',
    storageBucket: 'vectordesk-b445c.firebasestorage.app',
    iosBundleId: 'com.koso.vectordesk',
  );
}
