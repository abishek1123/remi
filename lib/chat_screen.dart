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
        headers: {'Content-Type': 'application/json'},
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: kRed, size: 48),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _greeting,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800),
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
            const SizedBox(height: 8),
            const Text(
              'Add tasks, ask your documents, or just talk.',
              style: TextStyle(color: kTextSecondary),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _examplePrompts
                  .map(
                    (p) => ActionChip(
                      label: Text(p, style: const TextStyle(fontSize: 12)),
                      backgroundColor: kSurface,
                      side: const BorderSide(color: kSurfaceLight),
                      labelStyle: const TextStyle(color: kTextPrimary),
                      onPressed: () => _sendMessageText(p),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REMI',
            style: TextStyle(
              color: kRed,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 22,
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
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser ? kRed : kSurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              msg.content,
                              style: const TextStyle(color: kTextPrimary),
                            ),
                          ),
                          if (!isUser)
                            InkWell(
                              onTap: () => _tts.speak(msg.content),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.volume_up_outlined,
                                    size: 18, color: kTextSecondary),
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
