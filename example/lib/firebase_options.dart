// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
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
}
