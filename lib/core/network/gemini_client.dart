import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Backend-Proxied AI Transport Client
/// ──────────────────────────────────────────────────────────
/// Singleton that provides A2uiTransportAdapter instances
/// wired to the FastAPI backend's POST /chat/stream endpoint.
///
/// Phase 3 Architecture:
///   Flutter sends user message + userId → FastAPI backend
///   Backend fetches Supabase profile, injects A2UI system
///   instruction, calls Gemini with streaming, returns SSE
///   Flutter reads SSE chunks → addChunk() → GenUI pipeline
///
/// The GenUI rendering pipeline is unchanged:
///   addChunk(chunk) → A2uiParserTransformer → SurfaceController → Surface
///
/// System instruction now lives in the Python backend (main.py).
/// The google_generative_ai Flutter package is no longer needed.
/// ──────────────────────────────────────────────────────────

class GeminiClient {
  // ── Singleton ──────────────────────────────────────────
  static final GeminiClient _instance = GeminiClient._internal();
  factory GeminiClient() => _instance;
  GeminiClient._internal();

  /// Always true — no client-side Gemini initialization needed.
  /// Backend handles all AI configuration.
  bool get isInitialized => true;

  /// Authenticated user's UUID — set by views that have access
  /// to AuthStateNotifier. Used in the /chat/stream request payload.
  String? _userId;

  void setUserId(String? userId) {
    _userId = userId;
    debugPrint('[GeminiClient] userId set: $userId');
  }

  /// Base URL for the FastAPI backend.
  /// Android emulator routes `10.0.2.2` → host machine's `localhost`.
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  /// No-op initialization for backward compatibility.
  /// Previously initialized the Gemini SDK — now the backend handles it.
  Future<void> initialize() async {
    debugPrint('[GeminiClient] ✅ Backend-proxied mode — no client init needed.');
  }

  // ── Transport Adapter Factory ──────────────────────────

  /// Creates an [A2uiTransportAdapter] wired to the FastAPI backend.
  ///
  /// The adapter's [onSend] callback:
  ///   1. Sends POST /chat/stream with {user_id, user_message}
  ///   2. Reads the SSE response stream chunk-by-chunk
  ///   3. Parses `data: <text>` lines and feeds each chunk
  ///      to [A2uiTransportAdapter.addChunk]
  ///   4. Stops on `[DONE]` sentinel
  ///
  /// The GenUI SDK pipeline (SurfaceController, Surface widgets)
  /// continues to work identically — only the chunk source changed.
  A2uiTransportAdapter buildTransportAdapter() {
    late A2uiTransportAdapter adapter;

    adapter = A2uiTransportAdapter(
      onSend: (ChatMessage message) async {
        try {
          final userText = message.text;
          if (userText.isEmpty) return;

          debugPrint(
            '[GeminiClient] → Sending to backend: '
            '"${userText.substring(0, userText.length.clamp(0, 80))}…"',
          );

          // Build the streamed HTTP request
          final url = Uri.parse('$_baseUrl/chat/stream');
          final request = http.Request('POST', url)
            ..headers['Content-Type'] = 'application/json'
            ..body = jsonEncode({
              'user_id': _userId ?? '00000000-0000-0000-0000-000000000000',
              'user_message': userText,
            });

          final client = http.Client();
          try {
            final response = await client.send(request).timeout(
              const Duration(seconds: 60),
            );

            if (response.statusCode != 200) {
              debugPrint(
                '[GeminiClient] ❌ Backend error: ${response.statusCode}',
              );
              adapter.addChunk(
                'Backend sunucusuna bağlanılamadı '
                '(HTTP ${response.statusCode}). '
                'Lütfen sunucunun çalıştığından emin olun.',
              );
              return;
            }

            // ── SSE Stream Parser ────────────────────────
            // The backend sends SSE-formatted chunks:
            //   data: <text chunk>\n\n
            //   data: [DONE]\n\n
            //
            // Network may split TCP packets at arbitrary
            // boundaries, so we buffer partial lines and
            // parse complete "data: " prefixed lines.
            String buffer = '';

            await for (final rawChunk
                in response.stream.transform(utf8.decoder)) {
              buffer += rawChunk;

              // Process all complete SSE events in the buffer
              while (buffer.contains('\n\n')) {
                final eventEnd = buffer.indexOf('\n\n');
                final event = buffer.substring(0, eventEnd);
                buffer = buffer.substring(eventEnd + 2);

                // Parse each line in the event (SSE can have multi-line data)
                for (final line in event.split('\n')) {
                  if (line.startsWith('data: ')) {
                    final payload = line.substring(6); // Strip "data: " prefix

                    // Check for stream-end sentinel
                    if (payload == '[DONE]') {
                      debugPrint('[GeminiClient] ✅ Stream complete.');
                      return;
                    }

                    // Feed the chunk into the GenUI pipeline
                    if (payload.isNotEmpty) {
                      adapter.addChunk(payload);
                    }
                  }
                }
              }
            }

            // Process any remaining buffer content after stream ends
            if (buffer.trim().isNotEmpty) {
              for (final line in buffer.split('\n')) {
                if (line.startsWith('data: ')) {
                  final payload = line.substring(6);
                  if (payload != '[DONE]' && payload.isNotEmpty) {
                    adapter.addChunk(payload);
                  }
                }
              }
            }
          } finally {
            client.close();
          }
        } catch (e) {
          debugPrint('[GeminiClient] ❌ Stream error: $e');
          // Pipe a safe fallback text so the UI doesn't hang.
          adapter.addChunk(
            'Sistemde anlık bir yoğunluk var. '
            'Lütfen 1 dakika bekleyip tekrar deneyin.',
          );
        }
      },
    );

    return adapter;
  }
}
