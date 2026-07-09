# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`vectordesk_flutter` is a Flutter **package** (SDK), not an app. It ships a drop-in
`VectorDeskChatWidget` that connects a host Flutter app to the VectorDesk AI chat
backend, which lives entirely in Firebase (Firestore for data, Firebase Auth for
anonymous identity). There is no server code in this repo — all backend logic
(agent replies, RAG, channel integrations) happens outside this codebase; this SDK
only reads/writes Firestore documents and renders them.

The `example/` directory is a runnable Flutter app that depends on this package via
a git dependency (not a path dependency) — see `example/pubspec.yaml`. Keep that in
mind when testing local changes: the example does not automatically pick up edits to
`lib/` the way a path dependency would.

## Repository layout

- `lib/vectordesk_flutter.dart` — the single public entrypoint; exports everything
  under `lib/src/`. Nothing outside `lib/src/` should be added except more exports
  here.
- `lib/src/vectordesk_client.dart` — `VectorDeskClient`: all Firebase/Firestore
  logic (auth, chat lookup/creation, message send/stream). No UI code.
- `lib/src/vectordesk_chat_widget.dart` — `VectorDeskChatWidget`: the entire chat UI
  (message list, bubbles, input bar, image viewer, markdown rendering) as one
  `StatefulWidget`. This is the largest file and the one most edits will touch.
- `lib/src/models.dart` — `VectorDeskMessage` / `VectorDeskAttachment`, plain data
  classes with `fromFirestore`/`fromMap` factories. No Firestore writes happen here.
- `lib/src/localization.dart` — `VectorDeskChatTranslations` abstract interface and
  the built-in `VectorDeskChatDefaultTranslations` (English).
- `lib/src/vectordesk_firebase_options.dart` — hardcoded default `FirebaseOptions`
  per platform (web/android/ios) for the VectorDesk demo Firebase project. These are
  public client keys (Firestore security rules do the real access control), used only
  when the host app doesn't supply its own `firebaseOptions`.
- `example/` — standalone Flutter app exercising the widget; has its own
  `pubspec.yaml`, `firebase_options.dart`, and platform folders (android/ios/web/etc).

## Commands

Run these from the repo root unless noted. This is a Dart/Flutter package — there is
no separate build step; "building" means `flutter analyze`/`flutter test` passing and
the example app compiling.

```sh
# Package: install deps, analyze, format
flutter pub get
flutter analyze
dart format --set-exit-if-changed lib

# Package: run tests (currently no test/ directory or tests exist for the package itself)
flutter test

# Example app: install deps (also fetches vectordesk_flutter from GitHub master)
cd example && flutter pub get

# Example app: analyze / run a single test
cd example && flutter analyze
cd example && flutter test test/widget_test.dart

# Example app: run on a device/emulator or Chrome
cd example && flutter run
cd example && flutter run -d chrome
```

Notes:
- There is no top-level `analysis_options.yaml` for the package itself (only
  `example/analysis_options.yaml`, which just includes `package:flutter_lints`).
  `flutter analyze` on the package root uses Flutter/Dart defaults.
- `example/test/widget_test.dart` is the unmodified Flutter counter-app template
  test (`find.text('0')`/tap `Icons.add`) — it does not test `MyApp` in
  `example/lib/main.dart` (which has no counter) and will fail if run. Don't treat it
  as a meaningful regression signal; if you touch example tests, replace it with a
  real test rather than "fixing" it to pass superficially.
- Because `example/pubspec.yaml` pulls `vectordesk_flutter` from
  `git-url:...ref=master`, testing a local `lib/` change through the example app
  requires either a temporary `dependency_overrides:` (path to repo root) or
  publishing/pushing to `master` first.

## Architecture

### Data flow: Firestore as the only backend

Everything goes through `VectorDeskClient` (`lib/src/vectordesk_client.dart`):

1. **`initialize()`** gets-or-creates a named secondary `FirebaseApp` (default name
   `'vectordesk'`, overridable via `appName`) so the SDK's Firebase project doesn't
   collide with the host app's own default Firebase app. It then signs in
   anonymously via `FirebaseAuth.instanceFor(app: ...)` if no user is signed in —
   anonymous auth **must** be enabled in the target Firebase project, or
   `initialize()` throws.
2. **Chat resolution** (`_getOrCreateChatId`): queries
   `chats` where `orgId == orgId && userId == currentUser.uid && status == 'active'`,
   ordered by `lastMessageAt desc`, limit 1. If found, it patches `personaId` if it
   changed. If not found, it creates a new doc with id `guest_<uuid>` and a fixed set
   of fields (`orgId`, `userId`, `externalUserId`, `status: 'active'`,
   `channel: 'flutter_app'`, `integrationId: 'flutter_app'`, `humanTakeover: false`,
   etc.). **These field names/values are a contract with the VectorDesk backend** —
   don't rename or omit them without checking how the backend (RAG matching, channel
   routing) consumes them.
3. **`chatStream`** is an `async*` generator: it awaits `initialize()`, resolves the
   chat id, then streams `chats/{chatId}/messages` ordered by `createdAt desc`. This
   is the single stream the widget's `StreamBuilder` listens to for the message list.
4. **`sendMessage`** truncates text over 2050 chars, appends a `messages` doc with
   `senderType: 'user'`, and bumps the parent chat's `lastMessageAt`. It does not
   wait for or trigger the agent reply — that happens server-side and arrives back
   through the same `messages` stream as a doc with a different `senderType`.

`VectorDeskMessage.fromFirestore` maps Firestore's `senderType` field to `'user'` vs
`'agent'` (anything not `'user'` becomes `'agent'`) — this is the only place sender
identity is decided.

### Widget layer

`VectorDeskChatWidget` owns one `VectorDeskClient` instance for its lifetime, rebuilt
in `didUpdateWidget` only if `orgId`/`personaId`/`firebaseOptions`/`appName` change.
It listens to `_client.chatStream` twice: once via a manual `StreamSubscription` in
`_initClient` purely to flip `_isThinking` off when an agent message arrives, and
again via `StreamBuilder` in `build()` to render the list. Keep both in sync if you
change the stream's shape.

Key UI conventions to preserve when editing:
- **Theming**: a single `themeColor` drives bubble colors, send button, quick-reply
  chips; dark/light is decided by `widget.brightness ?? Theme.of(context).brightness`
  (`_isDark` getter), not by reading `ThemeData` colors directly — don't introduce
  colors that ignore `_isDark`.
- **Localization**: all user-facing strings go through `_l10n` (the injected
  `VectorDeskChatTranslations`, defaulting to `VectorDeskChatDefaultTranslations`).
  Never hardcode new UI strings — add a method/getter to
  `VectorDeskChatTranslations` and its default implementation in
  `lib/src/localization.dart`, then thread it through `_l10n` in the widget (see
  README's "Localization (i18n)" section for the pattern consumers follow).
- **Markdown + inline images**: message text is rendered with `flutter_markdown`.
  Before rendering, a regex rewrites the backend's `[IMAGE: <url>]` token into
  standard Markdown image syntax (`![image](url)`) so it flows through
  `MarkdownBody`'s `imageBuilder`. Separately, structured `attachments` (type
  `image`) are rendered above the text; an attachment whose `url == '[已過期]'` is
  treated as an expired-image placeholder. If you change one image path, check
  whether the other needs the same treatment.
- Tapping any rendered image opens a fullscreen `InteractiveViewer` via
  `_openFullscreenImage`; tapping a markdown link uses `url_launcher` and falls back
  to a snackbar (`_l10n.linkOpenFailed`) if the link can't be launched.

## Other things worth knowing

- `README.md` contains, in addition to SDK usage docs, a long unrelated section
  ("Channel Integration: Facebook for Business") documenting how to wire up
  Messenger/Instagram channels in the VectorDesk **web console/backend** — that part
  describes infrastructure outside this repo entirely and isn't SDK API
  documentation. Don't assume code in this repo implements it.
- Firebase dependencies (`firebase_core`, `cloud_firestore`, `firebase_auth`) are
  pinned with fairly wide ranges in `pubspec.yaml`; when bumping them, check both the
  package's `pubspec.yaml` and `example/pubspec.yaml`.
