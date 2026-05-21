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
    apiKey: 'AIzaSyBu6xQuPNLN3tPitjPan_Pa0CRGVQu1Uqs',
    appId: '1:139743525362:web:7903aba9d931403c76936b',
    messagingSenderId: '139743525362',
    projectId: 'vectordesk-b445c',
    authDomain: 'vectordesk-b445c.firebaseapp.com',
    storageBucket: 'vectordesk-b445c.firebasestorage.app',
    measurementId: 'G-D08SCKX953',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBsYNIJl9v0lj4l4N0OtOGGNeJv8YMVKGg',
    appId: '1:139743525362:android:d4de0eaf098f68c276936b',
    messagingSenderId: '139743525362',
    projectId: 'vectordesk-b445c',
    storageBucket: 'vectordesk-b445c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDYOyqTNTmDXZcAVWHAFUcyyJQiBBMQ2aE',
    appId: '1:139743525362:ios:2cd70490dfcc957676936b',
    messagingSenderId: '139743525362',
    projectId: 'vectordesk-b445c',
    storageBucket: 'vectordesk-b445c.firebasestorage.app',
    iosBundleId: 'app.whiles.aiagent.aiAgent',
  );
}
