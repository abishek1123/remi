import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';

class LearningGraphScreen extends StatefulWidget {
  const LearningGraphScreen({super.key});

  @override
  State<LearningGraphScreen> createState() => LearningGraphScreenState();
}

class LearningGraphScreenState extends State<LearningGraphScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _topics = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .rpc('topic_mastery', params: {'match_user_id': userId});
      setState(() {
        _topics = List<Map<String, dynamic>>.from(data as List);
      });
    } catch (e) {
      debugPrint('Failed to load learning graph: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _masteryColor(double m) {
    if (m >= 0.8) return Colors.green;
    if (m >= 0.5) return Colors.orange;
    return kRed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _topics.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Take a quiz on your documents to start building your learning graph.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextSecondary),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Topics to review',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Weakest first — focus here next.',
                        style: TextStyle(color: kTextSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ..._topics.map(_topicTile),
                    ],
                  ),
                ),
    );
  }

  Widget _topicTile(Map<String, dynamic> t) {
    final mastery = (t['mastery'] as num?)?.toDouble() ?? 0.0;
    final correct = t['correct'] ?? 0;
    final total = t['total'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  t['topic'] ?? 'General',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('$correct/$total',
                  style: const TextStyle(color: kTextSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: mastery,
              minHeight: 8,
              backgroundColor: kSurfaceLight,
              color: _masteryColor(mastery),
            ),
          ),
        ],
      ),
    );
  }
}
