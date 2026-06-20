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

---

## Channel Integration: Facebook for Business

This section documents the complete setup process for connecting a **Facebook Business Messenger** channel to VectorDesk, using **Facebook Login for Business** (Business Manager OAuth).

This flow differs from the standard Facebook OAuth — it is designed for businesses managing Pages via Meta Business Manager, using a `config_id` instead of OAuth scopes.

> ⚠️ **Critical gotcha**: A Meta App connected to a Business Manager account will **NOT deliver Messenger webhook events in Development Mode**, even for app administrators. You must switch the Meta App to **Live Mode** before webhooks work.

---

### Prerequisites

- A **Meta Business Manager** account with admin access
- One or more **Facebook Pages** managed under that Business Manager
- A **Meta Developer App** of type "Business" (create at [developers.facebook.com](https://developers.facebook.com))
- Access to the VectorDesk web console (admin or owner role)

---

### Step 1 — Create and Configure the Meta App

1. Go to [Meta for Developers](https://developers.facebook.com) → **My Apps → Create App**
2. Select app type: **Business**
3. Under **Use Cases**, add:
   - **Messenger from Meta** (for Facebook Messenger)
   - **Manage Instagram messages and content** (for Instagram, optional)
4. Under **App Settings → Basic**, fill in:
   - App domain (e.g., `orangeai.tw`)
   - Privacy Policy URL
   - App icon
5. Note your **App ID** and **App Secret**

---

### Step 2 — Set Up Facebook Login for Business

1. Navigate to **商家專用 Facebook 登入 (Facebook Login for Business)** in the left menu
2. Create a **configuration** — this generates a `config_id`
3. Set the **OAuth redirect URI** to your backend callback URL:
   ```
   https://{region}-{project}.cloudfunctions.net/facebookBusinessOauthCallback
   ```
4. Note the `config_id` — it replaces the `scope` parameter in the standard OAuth URL

---

### Step 3 — Configure Webhooks

#### Facebook Messenger Webhook
Navigate to **Messenger from Meta → Messenger API 設定 → Step 1 Webhooks**:

| Field | Value |
|-------|-------|
| Callback URL | `https://{region}-{project}.cloudfunctions.net/facebookBusinessOauthWebhook` |
| Verify Token | Your `META_WEBHOOK_VERIFY_TOKEN` value |
| Subscribed Fields | `messages`, `messaging_postbacks` |

#### Instagram Webhook (optional)
Navigate to **Messenger from Meta → Instagram 設定 → Webhooks**:

| Field | Value |
|-------|-------|
| Callback URL | `https://{region}-{project}.cloudfunctions.net/instagramBusinessOauthWebhook` |
| Verify Token | Same `META_WEBHOOK_VERIFY_TOKEN` value |
| Subscribed Fields | `messages`, `messaging_postbacks` |

---

### Step 4 — Request Permissions

Under **Messenger from Meta → 權限和功能 (Permissions and Features)**, ensure the following permissions are enabled:

| Permission | Purpose |
|-----------|---------|
| `public_profile` | Identify the authorizing user during OAuth |
| `business_management` | Access Business Manager and enumerate owned Pages |
| `pages_show_list` | Display Page list for the admin to select during binding |
| `pages_manage_metadata` | Subscribe the selected Page to Messenger webhooks |
| `pages_messaging` | Receive and reply to Messenger conversations |

For Instagram, additionally request:
| Permission | Purpose |
|-----------|---------|
| `instagram_basic` | Read Instagram Business account ID and username |
| `instagram_manage_messages` | Receive and send Instagram Direct Messages |

---

### Step 5 — Switch App to Live Mode (Critical!)

> ❌ **Do NOT skip this step.** Webhook events are silently dropped in Development Mode for Business Manager apps.

1. In the Meta App Dashboard, go to **發佈 (Publish)** in the left navigation
2. Confirm all required settings are complete
3. Click **發佈 (Publish)** to switch the app to **Live Mode**

**Why this is required**: Unlike standard Facebook Apps where Development Mode only restricts which users can interact, apps connected to a Business Manager account have an additional restriction — Meta does not deliver Messenger webhook POST events at all while in Development Mode, regardless of the user's app role (admin/developer/tester). The UI may show "success" when testing, but no events reach the server until Live Mode is enabled.

---

### Step 6 — Connect Facebook Channel in VectorDesk

1. Log in to the VectorDesk web console
2. Navigate to your Organization **Settings → Channels**
3. Click **Add Channel → Facebook Business**
4. Click **Connect with Facebook Business Login**
5. Complete the Meta Business Login OAuth flow:
   - Authorize the app with your Business Manager account
   - Select the Facebook Page to connect
6. After successful authorization, the channel appears as **Active** in your channel list

The OAuth flow calls:
- `/{user_id}/businesses` → lists your Business Manager accounts
- `/{business_id}/owned_pages` → lists Pages managed by the Business
- `POST /{page_id}/subscribed_apps` → subscribes the Page to webhook events

---

### Step 7 — Verify End-to-End

1. Send a test message to the connected Facebook Page via Messenger
2. The message should appear in the VectorDesk **Inbox** within a few seconds
3. Verify in GCP Cloud Logging that `facebookBusinessOauthWebhook` received a `POST` request

If messages are not appearing, check:
- ✅ App is in **Live Mode** (not Development Mode)
- ✅ Webhook URL is verified and subscribed to `messages` field
- ✅ The Page is subscribed to the Business App (`/{pageId}/subscribed_apps`)
- ✅ Firestore Collection Group index for `config.pageId` is deployed

---

### App Review

For **Standard Access** (responding to users who initiate conversation), no App Review is required. For **Advanced Access** (proactively messaging users), submit for review with:

- Written description for each permission (see VectorDesk internal docs for templates)
- Screen recording demonstrating the complete authorization and messaging flow

