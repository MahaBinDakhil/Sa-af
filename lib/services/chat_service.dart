// lib/services/chat_service.dart
//
// Sa'af chatbot (Gemini through Firebase AI Logic).
// Answers are grounded in Firestore: diseases/{diseaseId} -> description, symptoms, treatment.
// No API key in the app and no extra server.
//
// Setup (once):  flutter pub add firebase_ai
// Requires:      the user is logged in (FirebaseAuth), otherwise an exception is thrown.
//
// ═════════════════════════════════════════════════════════════════════════
// FUNCTIONS
// ═════════════════════════════════════════════════════════════════════════
//
//   ChatService.startChat({scanId, diseaseId, title})  -> Future<String> chatId
//       Creates users/{uid}/chats/{chatId}. Call once when the chat screen opens.
//
//   ChatService.send({chatId, history, userText, diseaseId, confidence, language})
//                                                      -> Future<ChatMessage> (bot reply)
//       Saves the user message, asks Gemini, saves the reply, returns the reply.
//       Never throws for AI problems: on errors it returns a friendly bot message.
//       Takes ~1-5 seconds -> show a "typing..." indicator while waiting.
//
//   ChatService.messagesStream(chatId)                 -> Stream<List<ChatMessage>>
//       Live list of all messages in the chat, oldest first (updates by itself).
//
//   ChatService.saveBotImage(chatId, text, imageUrl)   -> Future<void>
//       Adds a bot message with an image (only if the image has a URL).
//
// ═════════════════════════════════════════════════════════════════════════
// ChatMessage FIELDS
// ═════════════════════════════════════════════════════════════════════════
//
//   sender      "user" or "bot"
//   isUser      true -> right bubble with user icon, false -> left bubble with bot avatar
//   text        the message text (bot answers may contain "- " bullet lines)
//   imageUrl    optional image link (null if none)
//   createdAt   DateTime (can be null for a split second before the server time arrives)
//
// ═════════════════════════════════════════════════════════════════════════
// TWO WAYS TO OPEN THE CHAT
// ═════════════════════════════════════════════════════════════════════════
//
//   A) From a scan ("Ask the Chatbot" / "Ask the Chatbot about this"):
//        pass the scan's values -> answers are about THAT disease
//        final chatId = await ChatService.startChat(
//            scanId: scanId, diseaseId: result.diseaseId,
//            title: '${result.diseaseName} question');
//        ...and use diseaseId: result.diseaseId, confidence: result.confidence in send()
//
//   B) From the bottom nav bar (no scan):
//        final chatId = await ChatService.startChat(title: 'New chat');
//        ...and use diseaseId: null in send()  -> general date palm questions
//
//   Healthy scan: diseaseId: 'healthy' -> the bot gives general care tips.
//
// ═════════════════════════════════════════════════════════════════════════
// FULL EXAMPLE (chat screen)
// ═════════════════════════════════════════════════════════════════════════
//
//   String? chatId;
//   List<ChatMessage> messages = [];
//   bool isTyping = false;
//
//   @override
//   void initState() {
//     super.initState();
//     ChatService.startChat(scanId: widget.scanId, diseaseId: widget.diseaseId,
//                           title: 'Palm question')
//         .then((id) => setState(() => chatId = id));
//   }
//
//   Future<void> onSend(String text) async {
//     if (chatId == null || text.trim().isEmpty) return;
//     setState(() => isTyping = true);
//     await ChatService.send(
//       chatId: chatId!,
//       history: messages,
//       userText: text.trim(),
//       diseaseId: widget.diseaseId,      // null when opened from the nav bar
//       confidence: widget.confidence,    // null when opened from the nav bar
//       language: 'en',                   // 'ar' for Arabic answers
//     );
//     setState(() => isTyping = false);
//   }
//
//   // in build():
//   StreamBuilder<List<ChatMessage>>(
//     stream: chatId == null ? null : ChatService.messagesStream(chatId!),
//     builder: (context, snap) {
//       messages = snap.data ?? [];
//       if (messages.isEmpty) return WelcomeView();   // "Hello / How can I help you?"
//       return ListView(children: [
//         for (final m in messages) MessageBubble(message: m),
//         if (isTyping) TypingIndicator(),
//       ]);
//     },
//   );
//
// ═════════════════════════════════════════════════════════════════════════
// FIGMA SCREENS
// ═════════════════════════════════════════════════════════════════════════
//
//   Welcome view ("Hello / How can I help you?")
//       show it while the messages list is empty.
//
//   Quick-reply buttons -> just call onSend with the button text:
//       "How can I treat this disease?"      -> onSend('How can I treat this disease?')
//       "How did you identify this disease?" -> onSend('How did you identify this disease?')
//       Hide both when the chat was opened from the nav bar (no disease).
//
//   "Here is how the model detected the disease symptoms:" + heatmap image
//       The heatmap comes from the model server, not from the chatbot:
//         final xai = await ModelService.explain(photo);     // model_service.dart
//         Image.memory(xai.heatmap!)
//       Show it inside a bot bubble under the text answer of
//       "How did you identify this disease?" (the photo File must be passed
//       to the chat screen). It is a local image, so it is NOT saved in Firestore.
//
//   Text field "Ask Sa'af AI..." -> onSend(controller.text), then controller.clear()
//
// ═════════════════════════════════════════════════════════════════════════
// FIRESTORE (written automatically, nothing to do by hand)
// ═════════════════════════════════════════════════════════════════════════
//
//   users/{uid}/chats/{chatId}                 scanId, diseaseId, title, createdAt, lastMessageAt
//   users/{uid}/chats/{chatId}/messages/{id}   sender, text, imageUrl, createdAt
//   diseases/{diseaseId}                       read only (name, description, symptoms, treatment)
//
// ═════════════════════════════════════════════════════════════════════════
// LIMITS & ERRORS
// ═════════════════════════════════════════════════════════════════════════
//
//   - Free tier: only a few messages per minute. Over the limit, the reply is
//     "I'm getting a lot of questions right now. Please wait a minute..."
//   - No internet: "I couldn't connect. Please check your internet..."
//   - Other errors: "Sorry, something went wrong..." and the real error is printed
//     in the debug console ("ChatService error: ...").
//   - "model not found" in the console -> change geminiModel below to a model
//     listed in Firebase AI Logic.
//   - Answers are limited to ~120 words, about date palms only.
// ═════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'model_service.dart';

/// Change this if Firebase says the model is not available.
const String geminiModel = 'gemini-2.5-flash';

class ChatMessage {
  final String sender;        // "user" or "bot"
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;

  ChatMessage({required this.sender, required this.text, this.imageUrl, this.createdAt});

  bool get isUser => sender == 'user';

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data() ?? {};
    final img = (j['imageUrl'] ?? '').toString();
    return ChatMessage(
      sender: (j['sender'] ?? 'user').toString(),
      text: (j['text'] ?? '').toString(),
      imageUrl: img.isEmpty ? null : img,
      createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ChatService {
  static final _db = FirebaseFirestore.instance;

  static String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please log in first');
    return user.uid;
  }

  static CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('users').doc(_uid).collection('chats');

  // ---------------------------------------------------------------- chats
  /// Creates a new chat document and returns its id.
  static Future<String> startChat({String? scanId, String? diseaseId, String title = 'New chat'}) async {
    final doc = await _chats.add({
      'scanId': scanId ?? '',
      'diseaseId': diseaseId ?? '',
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Live list of messages in a chat, oldest first.
  static Stream<List<ChatMessage>> messagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromDoc).toList());
  }

  // ------------------------------------------------------------ messaging
  /// Saves the user's message, asks Gemini, saves and returns the bot reply.
  static Future<ChatMessage> send({
    required String chatId,
    required List<ChatMessage> history,
    required String userText,
    String? diseaseId,
    double? confidence,
    String language = 'en',
  }) async {
    await _saveMessage(chatId, 'user', userText);

    String replyText;
    try {
      final systemPrompt = await _buildSystemPrompt(diseaseId, confidence, language);

      final model = FirebaseAI.googleAI().generativeModel(
        model: geminiModel,
        systemInstruction: Content.system(systemPrompt),
        generationConfig: GenerationConfig(temperature: 0.3, maxOutputTokens: 600),
      );

      // previous messages (last 12) so the bot remembers the conversation
      final recent = history.length > 12 ? history.sublist(history.length - 12) : history;
      final chat = model.startChat(
        history: recent
            .where((m) => m.text.trim().isNotEmpty)
            .map((m) => m.isUser ? Content.text(m.text) : Content.model([TextPart(m.text)]))
            .toList(),
      );

      final response = await chat.sendMessage(Content.text(userText));
      replyText = (response.text ?? '').trim();
      if (replyText.isEmpty) {
        replyText = 'Sorry, I couldn\'t answer that. Please try asking in a different way.';
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('quota') || msg.contains('429') || msg.contains('resource_exhausted')) {
        replyText = 'I\'m getting a lot of questions right now. Please wait a minute and try again.';
      } else if (msg.contains('network') || msg.contains('socket')) {
        replyText = 'I couldn\'t connect. Please check your internet and try again.';
      } else {
        replyText = 'Sorry, something went wrong. Please try again.';
        // ignore: avoid_print
        print('ChatService error: $e');   // shows the real error in the debug console
      }
    }

    await _saveMessage(chatId, 'bot', replyText);
    return ChatMessage(sender: 'bot', text: replyText, createdAt: DateTime.now());
  }

  /// Saves a bot message with an image (e.g. the GradCAM++ heatmap link).
  static Future<void> saveBotImage(String chatId, String text, String imageUrl) =>
      _saveMessage(chatId, 'bot', text, imageUrl: imageUrl);

  // -------------------------------------------------------------- helpers
  /// Reads diseases/{diseaseId} from Firestore and builds Gemini's instructions.
  static Future<String> _buildSystemPrompt(String? diseaseId, double? confidence, String language) async {
    final lang = language == 'ar' ? 'Arabic' : 'English';
    final lines = <String>[
      'You are Sa\'af AI, a friendly assistant inside a date palm disease app.',
      'Answer questions about the palm\'s diagnosis, its symptoms and its treatment.',
      'Base your answers on the DISEASE INFORMATION below. It comes from the app\'s',
      'database and is the trusted source. Do not invent treatments, chemicals or',
      'doses that are not in it. If the answer is not in it, give only general,',
      'safe palm-care advice and suggest consulting an agricultural specialist.',
      'If the user asks about something unrelated to date palms, politely say you',
      'can only help with date palm health.',
      'Reply in $lang. Keep answers short (under 120 words) and use bullet points for steps.',
      'If the user asks how the disease was identified, explain that a hybrid AI model',
      '(EfficientNetV2-S + Swin Transformer) analysed the leaf photo, and the heatmap',
      'shows the areas it focused on.',
    ];

    if (diseaseId != null && diseaseId.isNotEmpty && diseaseId != 'healthy') {
      final doc = await _db.collection('diseases').doc(diseaseId).get();
      final d = doc.data() ?? {};
      final symptoms = List<String>.from(d['symptoms'] ?? const []);
      final treatment = List<String>.from(d['treatment'] ?? const []);

      lines.add('');
      lines.add('DISEASE INFORMATION');
      lines.add('Diagnosis: ${d['name'] ?? diseaseNames[diseaseId] ?? diseaseId}');
      if (confidence != null) lines.add('Model confidence: ${(confidence * 100).round()}%');
      if ((d['description'] ?? '').toString().isNotEmpty) lines.add('Description: ${d['description']}');
      if (symptoms.isNotEmpty) {
        lines.add('Symptoms:');
        lines.addAll(symptoms.map((s) => '- $s'));
      }
      if (treatment.isNotEmpty) {
        lines.add('Treatment:');
        lines.addAll(treatment.map((t) => '- $t'));
      }
    } else if (diseaseId == 'healthy') {
      lines.add('');
      lines.add('The scanned palm leaf was classified as HEALTHY. Give general care tips.');
    } else {
      lines.add('');
      lines.add('No scan is attached to this chat. Answer general date palm questions.');
    }
    return lines.join('\n');
  }

  static Future<void> _saveMessage(String chatId, String sender, String text, {String imageUrl = ''}) async {
    final chat = _chats.doc(chatId);
    await chat.collection('messages').add({
      'sender': sender,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await chat.update({'lastMessageAt': FieldValue.serverTimestamp()});
  }
}