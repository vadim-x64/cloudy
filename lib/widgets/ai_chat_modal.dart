import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/ai_service.dart';
import '../screens/home_screen.dart';

class AiChatModal extends StatefulWidget {
  final WeatherModel weather;
  final TempUnit selectedUnit;
  final List<Map<String, String>> chatHistory;

  const AiChatModal({
    super.key,
    required this.weather,
    required this.selectedUnit,
    required this.chatHistory,
  });

  @override
  State<AiChatModal> createState() => _AiChatModalState();
}

class _AiChatModalState extends State<AiChatModal> {
  final _aiService = AiService();
  final _textController = TextEditingController();

  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    if (widget.chatHistory.isEmpty) {
      _isLoading = true;
      _fetchGreeting();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchGreeting() async {
    final greeting = await _aiService.generateGreeting(widget.weather);
    if (mounted) {
      setState(() {
        _isLoading = false;
        widget.chatHistory.insert(0, {
          'role': 'assistant',
          'content': greeting ?? 'Привіт! Чим допомогти?',
          'isNew': 'true',
        });
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    for (var msg in widget.chatHistory) {
      msg['isNew'] = 'false';
    }

    setState(() {
      widget.chatHistory.insert(0, {'role': 'user', 'content': text, 'isNew': 'false'});
      _isLoading = true;
    });

    _textController.clear();

    String unitStr = widget.selectedUnit == TempUnit.celsius
        ? '°C'
        : (widget.selectedUnit == TempUnit.fahrenheit ? '°F' : 'K');

    final chatHistoryForApi = widget.chatHistory.reversed.map((m) => {
      'role': m['role']!,
      'content': m['content']!
    }).toList();

    final response = await _aiService.sendChatMessage(
      chatHistory: chatHistoryForApi,
      weather: widget.weather,
      unitStr: unitStr,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response != null) {
          widget.chatHistory.insert(0, {'role': 'assistant', 'content': response, 'isNew': 'true'});
        } else {
          widget.chatHistory.insert(0, {
            'role': 'assistant',
            'content': 'Вибачте, сталася помилка при з\'єднанні. Спробуйте ще раз.',
            'isNew': 'true'
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: EdgeInsets.only(bottom: bottomInset, left: 16, right: 16, top: 16),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade900.withOpacity(0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.chatHistory.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == 0) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    }

                    final msgIndex = _isLoading ? index - 1 : index;
                    final msg = widget.chatHistory[msgIndex];
                    final isUser = msg['role'] == 'user';
                    final isNewAssistantMsg = !isUser && msg['isNew'] == 'true';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.blueAccent.withOpacity(0.8)
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                          ),
                        ),
                        child: isNewAssistantMsg
                            ? ChatTypewriterText(text: msg['content']!)
                            : Text(
                          msg['content']!,
                          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Запитайте будь-що...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatTypewriterText extends StatefulWidget {
  final String text;

  const ChatTypewriterText({super.key, required this.text});

  @override
  State<ChatTypewriterText> createState() => _ChatTypewriterTextState();
}

class _ChatTypewriterTextState extends State<ChatTypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _characterCount;

  @override
  void initState() {
    super.initState();
    int charCount = widget.text.characters.length;
    _controller = AnimationController(
      duration: Duration(milliseconds: charCount * 20),
      vsync: this,
    );
    _characterCount = StepTween(
      begin: 0,
      end: charCount,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _characterCount,
      builder: (context, child) {
        String visibleText = widget.text.characters.take(_characterCount.value).toString();
        return Text(
          visibleText,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
        );
      },
    );
  }
}