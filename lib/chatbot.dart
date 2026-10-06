import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _bubble = Color(0xFFD9D9D9);
  static const Color _green = Color(0xFF2F4A35);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  final List<String> _suggestions = [
    'How can I treat this disease?',
    'How did you identify this disease?',
  ];

  void _send([String? preset]) {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'isUser': true});
    });
    _controller.clear();
    _scrollToEnd();

    // رد تجريبي من البوت (نستبدله بالربط الحقيقي لاحقاً)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add({'text': _fakeReply(text), 'isUser': false});
      });
      _scrollToEnd();
    });
  }

  String _fakeReply(String question) {
    if (question == 'How can I treat this disease?') {
      return 'Black Scorch Treatment:\n\n'
          '✂️ Prune: Cut & burn infected fronds.\n'
          '🧴 Spray: Apply copper-based fungicide.\n'
          '🧽 Disinfect: Sterilize pruning tools.\n'
          '💧 Dry: Keep the palm crown dry.';
    }
    if (question == 'How did you identify this disease?') {
      return 'Here is how the model detected the disease symptoms.';
    }
    return 'شكراً لسؤالك! سأرد عليك قريباً.';
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
        // حجم الدائرة يتكيف مع ارتفاع الشاشة
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
            const Text('How can i help you ?',
                style: TextStyle(fontSize: 20, color: Colors.black)),
            const Spacer(flex: 3),
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
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final m = _messages[i];
        final isUser = m['isUser'] as bool;
        final bubble = Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(m['text'], style: const TextStyle(fontSize: 14)),
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

  Widget _inputField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _controller,
        onSubmitted: (_) => _send(),
        decoration: InputDecoration(
          hintText: 'Ask PlamCare AI...',
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
                child: _messages.isEmpty ? _welcome() : _messageList(),
              ),
              _inputField(),
            ],
          ),
        ),
      ),
    );
  }
}