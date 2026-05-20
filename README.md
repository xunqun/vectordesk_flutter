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

### 4. Tool Integrations (e.g., Google Calendar)

The `VectorDeskChatWidget` automatically supports any AI tools configured for your organization in the VectorDesk console.

For example, if you have enabled the **Google Calendar** integration:
- The AI can seamlessly query your schedule or create new calendar events during a chat session.
- No additional frontend setup is required in your Flutter app; the widget natively handles tool execution states and renders the responses automatically.
- To use this, simply ensure the Google Calendar tool is enabled for your Agent Persona and that the required Google Account authorization has been completed in the VectorDesk web console.

#### Server-Side GCP Setup for Google Integrations

To enable Google Calendar, Google Docs, and Google Sheets integrations, you must configure OAuth 2.0 credentials in the Google Cloud Console (GCP). Since the AI Agent backend manages the OAuth flow and tool execution, these steps are performed on the server side (Cloud Functions) rather than in the Flutter client.

**1. Enable Required APIs**
1. Go to the [Google Cloud Console](https://console.cloud.google.com/) and select your Firebase project.
2. Navigate to **APIs & Services > Library**.
3. Search for and **Enable** the following APIs:
   - `Google Calendar API`
   - `Google Docs API`
   - `Google Sheets API`

**2. Configure OAuth Consent Screen**
1. Go to **APIs & Services > OAuth consent screen**.
2. Select **External** (or Internal if using a Workspace domain) and click Create.
3. Fill in the App Information (App name, User support email).
4. Add the following scopes: `.../auth/calendar`, `.../auth/documents`, `.../auth/spreadsheets`.
5. Save and add your test Google accounts to the "Test users" list if the app is still in the "Testing" state.

**3. Create OAuth 2.0 Client Credentials & Redirect URIs**
You can use a single Web Client for all three integrations, or create three separate ones.
1. Go to **APIs & Services > Credentials**.
2. Click **CREATE CREDENTIALS > OAuth client ID**.
3. Application type: **Web application**. Name it something like "AI Agent Google Tools Webhook".
4. Under **Authorized redirect URIs**, add the following URLs (replace `<YOUR_PROJECT_ID>` with your Firebase project ID, e.g., `vectordesk-dev-6b1f0`):
   - `https://asia-east1-<YOUR_PROJECT_ID>.cloudfunctions.net/calendarAuthCallback`
   - `https://asia-east1-<YOUR_PROJECT_ID>.cloudfunctions.net/docsAuthCallback`
   - `https://asia-east1-<YOUR_PROJECT_ID>.cloudfunctions.net/sheetsAuthCallback`
5. Click **Create**.

**4. Update Backend Environment Variables**
Copy the generated Client ID and Client Secret, and set them in your backend `functions/.env.dev` and `functions/.env.prod` files:

```env
# Google Calendar
GOOGLE_CALENDAR_CLIENT_ID="Your Client ID"
GOOGLE_CALENDAR_CLIENT_SECRET="Your Client Secret"

# Google Docs
GOOGLE_DOCS_CLIENT_ID="Your Client ID"
GOOGLE_DOCS_CLIENT_SECRET="Your Client Secret"

# Google Sheets
GOOGLE_SHEETS_CLIENT_ID="Your Client ID"
GOOGLE_SHEETS_CLIENT_SECRET="Your Client Secret"
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
