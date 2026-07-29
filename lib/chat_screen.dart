import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'main.dart' show logout;
import 'theme.dart';
import 'tts_service.dart';
import 'voice_settings.dart';
import 'text_utils.dart';
import 'api.dart';

class ChatMessage {
  final String role;
  final String content;
  ChatMessage({required this.role, required this.content});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _sending = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final TtsService _tts = TtsService.instance;
  bool _isListening = false;
  bool _speechAvailable = false;

  static const _examplePrompts = [
    'Remind me to submit the DBMS assignment on Friday',
    'Summarize my uploaded notes',
    'What does my document say about normalization?',
    "I'm feeling stressed about exams",
  ];

  static const _defaultGreeting = 'Hi, what do you need?';
  String _greeting = _defaultGreeting;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadGreeting();
  }

  Future<void> _loadGreeting() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('greeting_phrase');
    if (saved != null && saved.trim().isNotEmpty) {
      setState(() => _greeting = saved);
    }
  }

  Future<void> _editGreeting() async {
    final controller = TextEditingController(text: _greeting);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Custom greeting'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Welcome back, boss!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
    if (result == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (result.isEmpty) {
      await prefs.remove('greeting_phrase');
      setState(() => _greeting = _defaultGreeting);
    } else {
      await prefs.setString('greeting_phrase', result);
      setState(() => _greeting = result);
    }
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    await _tts.stop();
    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() => _isListening = false);
          _sendMessageText(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _sendMessage() async {
    await _sendMessageText(_controller.text.trim());
  }

  Future<void> _sendMessageText(String text) async {
    if (text.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _controller.clear();
      _sending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://web-production-3f04d.up.railway.app/assistant'),
        headers: jsonAuthHeaders(),
        body: jsonEncode({
          'messages': _messages
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
          'user_id': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Assistant failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final reply = cleanReply(data['reply'] as String);
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
      });
    } catch (e) {
      const reply = "Sorry, I couldn't respond right now.";
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
      });
    } finally {
      setState(() => _sending = false);
    }
  }

  Widget _emptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _greeting,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w600, height: 1.15),
                ),
              ),
              IconButton(
                onPressed: _editGreeting,
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: kTextSecondary),
                tooltip: 'Edit greeting',
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'TRY ASKING',
            style: TextStyle(
              fontSize: 11,
              color: kTextSecondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._examplePrompts.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _sendMessageText(p),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kDivider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 15, color: kAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(p,
                            style: const TextStyle(
                                fontSize: 14, color: kTextPrimary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REMI',
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
              fontSize: 18,
            )),
        actions: [
          IconButton(
            onPressed: () => showVoiceSettings(context),
            icon: const Icon(Icons.record_voice_over_outlined),
            tooltip: 'Voice settings',
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      return Column(
                        crossAxisAlignment: isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.82,
                            ),
                            decoration: BoxDecoration(
                              gradient: isUser
                                  ? const LinearGradient(
                                      colors: [kAccent600, kAccent700],
                                    )
                                  : null,
                              color: isUser ? null : kSurface,
                              border: isUser
                                  ? null
                                  : Border.all(color: kDivider),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isUser ? 16 : 4),
                                topRight: const Radius.circular(16),
                                bottomLeft: const Radius.circular(16),
                                bottomRight: Radius.circular(isUser ? 4 : 16),
                              ),
                            ),
                            child: Text(
                              msg.content,
                              style: TextStyle(
                                color: isUser ? kAccent100 : kTextPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          if (!isUser)
                            InkWell(
                              onTap: () => _tts.speak(msg.content),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.volume_up_outlined,
                                        size: 15, color: kAccentText),
                                    SizedBox(width: 4),
                                    Text('Listen',
                                        style: TextStyle(
                                            fontSize: 11, color: kAccentText)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _sendMessage,
                  icon: const Icon(Icons.send, color: kRed),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        backgroundColor: _isListening ? Colors.white : kRed,
        foregroundColor: _isListening ? kRed : Colors.white,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}
