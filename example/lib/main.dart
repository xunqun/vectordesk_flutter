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
    print('Firebase init error (expected if no options): $e');
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
          orgId: 'BKHmv6uGFlPoqPgOboa9',
          personaId: 'gWF3A6hEPQt57WW185zn',
        ),
      ),
    );
  }
}
