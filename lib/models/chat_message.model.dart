/// OnyxFi — Local Chat Message Model
///
/// Renamed from ChatMessage → OnyxChatMessage to avoid a name collision
/// with the `ChatMessage` class exported by the official `genui` SDK.
///
/// Represents a single message in the UI conversation log.
/// Only used for user-side text bubbles (AI responses are rendered
/// as native GenUI `Surface` widgets via `Conversation.sendRequest`).
library;

enum OnyxMessageRole { user, assistant, system }

class OnyxChatMessage {
  final String id;
  final OnyxMessageRole role;
  final String content;
  final DateTime timestamp;

  const OnyxChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Convenience factory for user messages shown in the chat log.
  factory OnyxChatMessage.user(String content) {
    return OnyxChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: OnyxMessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
  }
}
