import 'package:flutter/material.dart';
import 'services/chat_service.dart';

class ChatbotScreen extends StatefulWidget {
  final String? chatId;
  final String? diseaseId;
  final double? confidence;

  const ChatbotScreen({
    super.key,
    this.chatId,
    this.diseaseId,
    this.confidence,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _bubble = Color(0xFFD9D9D9);
  static const Color _green = Color(0xFF2F4A35);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  String? _activeChatId;
  String? _error;
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestions = [
    'How can I treat this disease?',
    'How did you identify this disease?',
  ];

  @override
  void initState() {
    super.initState();
    _activeChatId = widget.chatId;
    if (_activeChatId == null) _startChat();
  }

  void _startChat() {
    setState(() => _error = null);
    ChatService.startChat(
      diseaseId: widget.diseaseId,
      title: widget.diseaseId != null ? 'Scan Question' : 'New Chat',
    ).timeout(const Duration(seconds: 15)).then((id) {
      if (mounted) setState(() => _activeChatId = id);
    }).catchError((e) {
      debugPrint('startChat failed: $e');
      if (mounted) setState(() => _error = e.toString());
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _activeChatId == null) return;

    _controller.clear();
    setState(() => _isTyping = true);
    _scrollToEnd();

    try {
      await ChatService.send(
        chatId: _activeChatId!,
        history: _messages,
        userText: text,
        diseaseId: widget.diseaseId,
        confidence: widget.confidence,
        language: 'en', // Set to 'ar' for Arabic replies
      );
    } catch (e) {
      debugPrint('send failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر الإرسال: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToEnd();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFEDEDED),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _botAvatar({double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6E8B72), Color(0xFFB08A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _userAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black87),
      ),
      child: const Icon(Icons.person_outline, color: _green),
    );
  }

  Widget _welcome() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final avatarSize =
            (constraints.maxHeight * 0.32).clamp(100.0, 190.0);
        return Column(
          children: [
            const Spacer(flex: 2),
            _botAvatar(size: avatarSize),
            const SizedBox(height: 12),
            const Text('Hello',
                style: TextStyle(fontSize: 20, color: Colors.black38)),
            const SizedBox(height: 8),
            const Text('How can I help you?',
                style: TextStyle(fontSize: 20, color: Colors.black)),
            const Spacer(flex: 3),

            // Show quick suggestions only when attached to a disease scan
            if (widget.diseaseId != null)
              ..._suggestions.map(
                (s) => Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 16),
                    child: OutlinedButton(
                      onPressed: () => _send(s),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                      child: Text(s),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _messageList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) {
          return _buildTypingIndicator();
        }

        final m = _messages[i];
        final isUser = m.isUser;
        final bubble = Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? _green : _bubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              m.text,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: isUser
                ? [bubble, const SizedBox(width: 8), _userAvatar()]
                : [_botAvatar(), const SizedBox(width: 8), bubble],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _bubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Sa\'af AI is thinking...',
              style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _controller,
        onSubmitted: (_) => _send(),
        decoration: InputDecoration(
          hintText: 'Ask Sa\'af AI...',
          hintStyle: const TextStyle(color: Colors.black38),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: _green),
            onPressed: () => _send(),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black87),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _green, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تعذّر فتح المحادثة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _startChat,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleButton(Icons.chevron_left, () {
                      Navigator.maybePop(context);
                    }),
                    _circleButton(Icons.more_vert, () {}),
                  ],
                ),
              ),
              Expanded(
                child: _error != null
                    ? _errorView()
                    : _activeChatId == null
                        ? const Center(child: CircularProgressIndicator())
                        : StreamBuilder<List<ChatMessage>>(
                            stream: ChatService.messagesStream(_activeChatId!),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                        'خطأ في تحميل الرسائل:\n${snapshot.error}',
                                        textAlign: TextAlign.center),
                                  ),
                                );
                              }
                              _messages = snapshot.data ?? [];
                              if (_messages.isEmpty && !_isTyping) {
                                return _welcome();
                              }
                              return _messageList();
                            },
                          ),
              ),
              _inputField(),
            ],
          ),
        ),
      ),
    );
  }
}