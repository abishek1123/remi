import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'theme.dart';
import 'tts_service.dart';
import 'quiz_screen.dart';

class QaMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  QaMessage({required this.role, required this.content});
}

class DocumentQaScreen extends StatefulWidget {
  final String documentId;
  final String documentTitle;

  const DocumentQaScreen({
    super.key,
    required this.documentId,
    required this.documentTitle,
  });

  @override
  State<DocumentQaScreen> createState() => _DocumentQaScreenState();
}

class _DocumentQaScreenState extends State<DocumentQaScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<QaMessage> _messages = [];
  bool _asking = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final TtsService _tts = TtsService.instance;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
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
          _askQuestionText(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _askQuestion() async {
    await _askQuestionText(_controller.text.trim());
  }

  Future<void> _askQuestionText(String question) async {
    if (question.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _messages.add(QaMessage(role: 'user', content: question));
      _controller.clear();
      _asking = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://web-production-3f04d.up.railway.app/ask-document'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'user_id': userId,
          'document_id': widget.documentId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Request failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final answer = data['answer'] as String;
      setState(() {
        _messages.add(QaMessage(role: 'assistant', content: answer));
      });
      await _tts.speak(answer);
    } catch (e) {
      const reply = "Sorry, I couldn't answer that right now.";
      setState(() {
        _messages.add(QaMessage(role: 'assistant', content: reply));
      });
      await _tts.speak(reply);
    } finally {
      setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentTitle),
        actions: [
          IconButton(
            tooltip: 'Quiz me on this',
            icon: const Icon(Icons.quiz_outlined, color: kRed),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  documentId: widget.documentId,
                  documentTitle: widget.documentTitle,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Ask a question about this document —\ntype it or use the mic.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kTextSecondary),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
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
                      );
                    },
                  ),
          ),
          if (_asking)
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
                      hintText: 'Ask about this document...',
                    ),
                    onSubmitted: (_) => _askQuestion(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _asking ? null : _askQuestion,
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
