# VectorDesk Flutter SDK

A Flutter client SDK for integrating VectorDesk AI chat into your application.

## Features

-   **Real-time AI Chat**: Connect seamlessly with your VectorDesk agents.
-   **Markdown Support**: Rich text rendering including bold, italics, lists, links, and code blocks.
-   **Customizable Theme**: Match your app's branding with easy color configuration.
-   **Easy Integration**: Drop-in widget for instant chat functionality.

## Installation

Add `vectordesk_flutter` to your `pubspec.yaml`:

```sh
flutter pub add vectordesk_flutter --git-url=https://github.com/xunqun/vectordesk_flutter.git --git-ref=master
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
import 'package:vectordesk_flutter/vectordesk_flutter.dart';

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

### 3. Localization (i18n)

The chat widget supports full localization through dependency injection. By default, it uses English texts, but you can pass your own translations to support any language.

There are 7 UI strings you can translate:

1.  `sendFailed`: Error text when a message fails to send.
2.  `errorMessage`: Error text for general widget loading failures.
3.  `thinking`: Status text when the AI is processing a response.
4.  `defaultGreeting`: The fallback greeting if `greetingMessage` is not provided.
5.  `imageExpired`: Placeholder text for expired image attachments.
6.  `linkOpenFailed`: Error text when the user clicks an invalid link.
7.  `inputHint`: Placeholder text in the text input field.

**Example: Implementing multi-language support (English, Chinese, Japanese, French, German)**

Create a custom translations class that implements `VectorDeskChatTranslations`:

```dart
import 'package:vectordesk_flutter/vectordesk_flutter.dart';

class MyCustomTranslations implements VectorDeskChatTranslations {
  final String languageCode;

  MyCustomTranslations(this.languageCode);

  @override
  String sendFailed(String error) {
    switch (languageCode) {
      case 'zh': return '傳送失敗: $error';
      case 'ja': return '送信失敗: $error';
      case 'fr': return 'Échec de l\'envoi: $error';
      case 'de': return 'Senden fehlgeschlagen: $error';
      default: return 'Send failed: $error';
    }
  }

  @override
  String errorMessage(String error) {
    switch (languageCode) {
      case 'zh': return '錯誤: $error';
      case 'ja': return 'エラー: $error';
      case 'fr': return 'Erreur: $error';
      case 'de': return 'Fehler: $error';
      default: return 'Error: $error';
    }
  }

  @override
  String get thinking {
    switch (languageCode) {
      case 'zh': return '思考中...';
      case 'ja': return '考え中...';
      case 'fr': return 'En train de penser...';
      case 'de': return 'Denkt nach...';
      default: return 'Thinking...';
    }
  }

  @override
  String get defaultGreeting {
    switch (languageCode) {
      case 'zh': return '您好！請問今天有什麼我可以幫忙的？';
      case 'ja': return 'こんにちは！今日はどのようにお手伝いしましょうか？';
      case 'fr': return 'Bonjour ! Comment puis-je vous aider aujourd\'hui ?';
      case 'de': return 'Hallo! Wie kann ich Ihnen heute helfen?';
      default: return 'Hello! How can I help you today?';
    }
  }

  @override
  String get imageExpired {
    switch (languageCode) {
      case 'zh': return '[圖片已過期]';
      case 'ja': return '[画像は期限切れです]';
      case 'fr': return '[Image expirée]';
      case 'de': return '[Bild abgelaufen]';
      default: return '[Image expired]';
    }
  }

  @override
  String linkOpenFailed(String href) {
    switch (languageCode) {
      case 'zh': return '無法開啟連結：$href';
      case 'ja': return 'リンクを開けません：$href';
      case 'fr': return 'Impossible d\'ouvrir le lien : $href';
      case 'de': return 'Link kann nicht geöffnet werden: $href';
      default: return 'Unable to open link: $href';
    }
  }

  @override
  String get inputHint {
    switch (languageCode) {
      case 'zh': return '輸入問題...';
      case 'ja': return 'メッセージを入力...';
      case 'fr': return 'Tapez un message...';
      case 'de': return 'Nachricht eingeben...';
      default: return 'Type a message...';
    }
  }
}
```

Pass the translations object to the widget and use Flutter's context to get the current system locale:

```dart
VectorDeskChatWidget(
  orgId: 'YOUR_ORG_ID',
  translations: MyCustomTranslations(Localizations.localeOf(context).languageCode),
)
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
