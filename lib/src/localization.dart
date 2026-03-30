/// Provides an internal interface for localizing chat widget strings.
abstract class VectorDeskChatTranslations {
  String sendFailed(String error);
  String errorMessage(String error);
  String get thinking;
  String get defaultGreeting;
  String get imageExpired;
  String linkOpenFailed(String href);
  String get inputHint;
}

/// The default English translations for VectorDeskChatWidget.
class VectorDeskChatDefaultTranslations implements VectorDeskChatTranslations {
  const VectorDeskChatDefaultTranslations();
  
  @override
  String sendFailed(String error) => 'Send failed: $error';

  @override
  String errorMessage(String error) => 'Error: $error';

  @override
  String get thinking => 'Thinking...';

  @override
  String get defaultGreeting => 'Hello! How can I help you today?';

  @override
  String get imageExpired => '[Image expired]';

  @override
  String linkOpenFailed(String href) => 'Unable to open link: $href';

  @override
  String get inputHint => 'Type a message...';
}
