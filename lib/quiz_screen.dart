import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'learning_graph_screen.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String topic;
  final String explanation;
  final String source; // 'notes' or 'related'

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.topic,
    required this.explanation,
    required this.source,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        question: j['question'] ?? '',
        options: List<String>.from(j['options'] ?? const []),
        correctIndex: j['correct_index'] ?? 0,
        topic: j['topic'] ?? 'General',
        explanation: j['explanation'] ?? '',
        source: j['source'] ?? 'notes',
      );
}

class QuizScreen extends StatefulWidget {
  final String documentId;
  final String documentTitle;

  const QuizScreen({
    super.key,
    required this.documentId,
    required this.documentTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _loading = true;
  String? _error;
  List<QuizQuestion> _questions = [];

  int _index = 0;
  int? _selected;
  bool _answered = false;
  int _score = 0;
  int _numQuestions = 10;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'You need to be signed in.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://web-production-3f04d.up.railway.app/generate-quiz'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'document_id': widget.documentId,
          'num_questions': _numQuestions,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(response.statusCode.toString());
      }

      final data = jsonDecode(response.body);
      final list = (data['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList();

      setState(() {
        _questions = list;
        _loading = false;
        _index = 0;
        _selected = null;
        _answered = false;
        _score = 0;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Couldn't build a quiz right now. Please try again.";
      });
    }
  }

  Future<void> _selectOption(int i) async {
    if (_answered) return;
    final q = _questions[_index];
    final correct = i == q.correctIndex;

    setState(() {
      _selected = i;
      _answered = true;
      if (correct) _score++;
    });

    // Record the attempt for the learning graph (fire-and-forget).
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client.from('quiz_attempts').insert({
          'user_id': userId,
          'document_id': widget.documentId,
          'topic': q.topic,
          'is_correct': correct,
        });
      } catch (e) {
        debugPrint('Failed to record quiz attempt: $e');
      }
    }
  }

  void _next() {
    if (_index >= _questions.length - 1) {
      setState(() => _index = _questions.length); // triggers results view
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  Widget _sourceBadge(String source) {
    final isNotes = source == 'notes';
    final color = isNotes ? Colors.green : const Color(0xFF4A90D9);
    final label = isNotes ? 'From your notes' : 'Related';
    final icon = isNotes ? Icons.description_outlined : Icons.public;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Color _optionColor(int i) {
    if (!_answered) return kSurface;
    final q = _questions[_index];
    if (i == q.correctIndex) return const Color(0xFF1B5E20); // green = correct
    if (i == _selected) return const Color(0xFF5E1B1B); // red = your wrong pick
    return kSurface;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz · ${widget.documentTitle}')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Building your quiz…',
                style: TextStyle(color: kTextSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kTextSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _generate, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_index >= _questions.length) {
      return _buildResults();
    }

    return _buildQuestion();
  }

  Widget _buildQuestion() {
    final q = _questions[_index];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${_index + 1} of ${_questions.length}',
                  style: const TextStyle(
                      color: kTextSecondary, fontWeight: FontWeight.w600)),
              _sourceBadge(q.source),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kSurfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(q.topic,
                  style: const TextStyle(color: kRed, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_index + 1) / _questions.length,
            backgroundColor: kSurface,
            color: kRed,
          ),
          const SizedBox(height: 20),
          Text(q.question,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 20),
          ...List.generate(q.options.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _selectOption(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _optionColor(i),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_answered && i == q.correctIndex)
                          ? Colors.green
                          : (_answered && i == _selected)
                              ? kRed
                              : kSurfaceLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(q.options[i])),
                      if (_answered && i == q.correctIndex)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                      if (_answered && i == _selected && i != q.correctIndex)
                        const Icon(Icons.cancel, color: kRed, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_answered) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: kTextSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(q.explanation,
                        style: const TextStyle(color: kTextSecondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_index >= _questions.length - 1
                    ? 'See results'
                    : 'Next question'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final total = _questions.length;
    final pct = total == 0 ? 0 : (_score / total * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_score / $total',
                style: const TextStyle(
                    fontSize: 48, fontWeight: FontWeight.w900, color: kRed)),
            const SizedBox(height: 8),
            Text('$pct% correct',
                style: const TextStyle(color: kTextSecondary, fontSize: 18)),
            const SizedBox(height: 32),
            const Text('Questions per quiz',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [10, 20, 30].map((count) {
                final selected = _numQuestions == count;
                return ChoiceChip(
                  label: Text('$count'),
                  selected: selected,
                  onSelected: (_) => setState(() => _numQuestions = count),
                  showCheckmark: false,
                  backgroundColor: kSurface,
                  selectedColor: kRed,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(color: selected ? kRed : kSurfaceLight),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generate,
                child: Text('New quiz ($_numQuestions questions)'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextPrimary,
                  side: const BorderSide(color: kTextSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const LearningGraphScreen()),
                ),
                child: const Text('View my progress'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
