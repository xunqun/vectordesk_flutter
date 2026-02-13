# VectorDesk Flutter SDK

A Flutter client SDK for integrating VectorDesk AI chat into your application.

## Features

-   **Real-time AI Chat**: Connect seamlessly with your VectorDesk agents.
-   **Markdown Support**: Rich text rendering including bold, italics, lists, links, and code blocks.
-   **Customizable Theme**: Match your app's branding with easy color configuration.
-   **Easy Integration**: Drop-in widget for instant chat functionality.

## Installation

Add `vector_desk_flutter` to your `pubspec.yaml`:

```sh
flutter pub add vector_desk_flutter
```

## Usage

### 1. Initialize Firebase

Ensure Firebase is initialized in your app (usually in `main.dart`):

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### 2. Add the Widget

Use `VectorDeskChatWidget` anywhere in your app. You can find your `orgId` and `personaId` in the VectorDesk console.

```dart
import 'package:vector_desk_flutter/vector_desk_flutter.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Support')),
      body: VectorDeskChatWidget(
        orgId: 'YOUR_ORG_ID', // Required
        personaId: 'YOUR_PERSONA_ID', // Optional (defaults to org's default persona)
        themeColor: Colors.blue, // Optional
      ),
    );
  }
}
```

## Markdown Support

The chat widget automatically renders Markdown syntax in messages.

-   **Bold**: `**text**`
-   *Italic*: `*text*`
-   [Links](https://vectordesk.ai)
-   Lists
-   `Code Blocks`

## Requirements

-   Flutter >=3.16.0
-   Dart >=3.2.0

## License

MIT
