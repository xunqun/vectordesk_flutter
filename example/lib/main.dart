import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vectordesk_flutter/vectordesk_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String orgId = '0898pqYLJXexekO5q0qg';
  static const String personaId = '7PmkG0BOc6Vs8blEPNw1';

  late final VectorDeskClient _client;
  StreamSubscription<VectorDeskMessage>? _newMessageSubscription;

  @override
  void initState() {
    super.initState();
    _client = VectorDeskClient.getInstance(orgId: orgId, personaId: personaId);

    // Initialize background listener so we receive incoming messages
    // even when the chat widget UI is not active.
    _client.startBackgroundListener();

    // Listen for new incoming messages for background notifications/snackbars
    _newMessageSubscription = _client.onNewMessage.listen((msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('收到客服新訊息: ${msg.text}'),
            action: SnackBarAction(
              label: '開啟',
              onPressed: _openChatScreen,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    super.dispose();
  }

  void _openChatScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(client: _client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VectorDesk Host App Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '宿主 App 主頁面',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '當離開聊天頁面時，下方按鈕會顯示新訊息未讀數 Badging',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            StreamBuilder<int>(
              stream: _client.unreadCountStream,
              initialData: _client.unreadCount,
              builder: (context, snapshot) {
                final unread = snapshot.data ?? 0;
                return ElevatedButton.icon(
                  onPressed: _openChatScreen,
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    child: const Icon(Icons.chat),
                  ),
                  label: Text('開啟 VectorDesk 客服對話 (${unread > 0 ? "$unread 未讀" : "無未讀"})'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final VectorDeskClient client;

  const ChatScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VectorDesk 在線客服'),
      ),
      body: VectorDeskChatWidget(
        orgId: client.orgId,
        personaId: client.personaId,
        client: client,
      ),
    );
  }
}

