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
        // Fallback or specific MacOS config if available.
        // For now, mirroring iOS config might work if bundle ID matches,
        // but typically MacOS has its own app registration.
        // If not supported, throw error.
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
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
    projectId: 'ai-agent-1ce5e',
    authDomain: 'ai-agent-1ce5e.firebaseapp.com',
    storageBucket: 'ai-agent-1ce5e.firebasestorage.app',
    measurementId: 'G-D08SCKX953',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBsYNIJl9v0lj4l4N0OtOGGNeJv8YMVKGg',
    appId: '1:139743525362:android:d4de0eaf098f68c276936b',
    messagingSenderId: '139743525362',
    projectId: 'ai-agent-1ce5e',
    storageBucket: 'ai-agent-1ce5e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDYOyqTNTmDXZcAVWHAFUcyyJQiBBMQ2aE',
    appId: '1:139743525362:ios:2cd70490dfcc957676936b',
    messagingSenderId: '139743525362',
    projectId: 'ai-agent-1ce5e',
    storageBucket: 'ai-agent-1ce5e.firebasestorage.app',
    iosBundleId: 'app.whiles.aiagent.aiAgent',
  );
}
