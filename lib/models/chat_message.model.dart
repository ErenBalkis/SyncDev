/// OnyxFi — Chat Message Model
///
/// Represents a single message in the AI chat conversation.
/// Supports both plain text and GenUI JSON payloads.
library;

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  /// Optional structured JSON payload for GenUI rendering.
  /// When present, the UI should render a dynamic widget
  /// instead of (or alongside) the text content.
  final Map<String, dynamic>? genUIPayload;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.genUIPayload,
  });

  /// Whether this message contains a GenUI component to render.
  bool get hasGenUI => genUIPayload != null && genUIPayload!.isNotEmpty;

  /// Factory constructor from Gemini GenUI JSON response.
  /// The response format from GeminiClient.sendAndParseGenUI:
  /// {"component_type": "...", "message": "...", "data": {...}}
  factory ChatMessage.fromAIResponse(Map<String, dynamic> json) {
    final componentType = json['component_type'] as String?;
    final data = json['data'];

    // Build the registry-compatible payload if it's not text_only
    Map<String, dynamic>? registryPayload;
    if (componentType != null && componentType != 'text_only') {
      registryPayload = {
        'type': componentType,
        'data': data is Map<String, dynamic> ? data : {},
      };
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: json['message'] as String? ?? '',
      timestamp: DateTime.now(),
      genUIPayload: registryPayload,
    );
  }

  /// Convenience factory for user messages.
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );
  }
}
