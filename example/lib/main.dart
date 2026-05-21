import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vectordesk_flutter/vectordesk_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We assume the host app initializes Firebase.
  // In a real scenario, the user would provide their firebase_options.dart
  // For this example, we'll use the copied one.
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error (expected if no options): $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('VectorDesk SDK Example')),
        body: const VectorDeskChatWidget(
          orgId: '0898pqYLJXexekO5q0qg',
          personaId: '7PmkG0BOc6Vs8blEPNw1',
        ),
      ),
    );
  }
}
