## 2.0.0

Protocol update for compatibility with tightened backend security rules.
Earlier SDK versions can no longer open or send to conversations; upgrade to
this version and republish your app.

*   Each anonymous user now has exactly one conversation per organization,
    stored under the fixed id `guest_<anonymous uid>_<orgId>`. The SDK reads it
    directly by id and creates it (with channel `flutter_app`) when absent; it
    no longer queries the conversation list.
*   New conversations no longer carry a `userId` field.
*   The SDK writes only the end user's messages plus the conversation's
    `lastMessageAt`, `status` (set back to `active`) and `personaId`. Agent replies and conversation state are
    written by the server.
*   **Behavior change:** conversations created by earlier SDK versions are not
    visible in this version. Users start a new conversation after upgrading.
*   **Behavior change:** the conversation is reused and is reopened (status set
    back to `active`) when the user sends a new message; the SDK no longer
    starts a fresh one when the previous one was closed.
*   The public API of `VectorDeskClient` and `VectorDeskChatWidget` is otherwise
    unchanged.
*   Removed the `uuid` dependency.

## 0.0.1

*   Initial release of VectorDesk Flutter SDK.
*   Support for real-time AI chat.
*   Markdown rendering support.
*   Customizable theme color.
