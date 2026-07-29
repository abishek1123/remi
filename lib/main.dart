import 'chat_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:table_calendar/table_calendar.dart';
import 'documents_screen.dart';
import 'learning_graph_screen.dart';
import 'theme.dart';
import 'tts_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is only configured for Android (no web firebase_options.dart yet),
  // so skip it on web to avoid a crash. Push notifications won't work on web until that's set up.
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }

  await Supabase.initialize(
    url: 'https://fkmkxaqyzszyjhnlkdif.supabase.co',
    anonKey: 'sb_publishable_rwtbXvewkIfodT5_diTPpQ_Bikas9cV',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

Future<void> _saveFcmToken() async {
  if (kIsWeb) return;

  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  final token = await messaging.getToken();
  if (token == null) return;

  await supabase.from('device_tokens').upsert({
    'user_id': userId,
    'fcm_token': token,
  }, onConflict: 'user_id,fcm_token');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remi',
      theme: buildAppTheme(),
      home: supabase.auth.currentSession == null
          ? const LoginScreen()
          : const RootShell(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      if (mounted && supabase.auth.currentSession != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RootShell()),
        );
      } else if (mounted && _isSignUp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email to confirm signup')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'PERSONAL AGENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kRed,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kTextSecondary),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(hintText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(hintText: 'Password'),
                      obscureText: true,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submit,
                            child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                          ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(_isSignUp
                          ? 'Already have an account? Sign in'
                          : "New here? Sign up now"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final GlobalKey<TasksTabState> _tasksKey = GlobalKey<TasksTabState>();
  final GlobalKey<LearningGraphScreenState> _graphKey =
      GlobalKey<LearningGraphScreenState>();

  @override
  void initState() {
    super.initState();
    _saveFcmToken();

    if (!kIsWeb) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${message.notification!.title}: ${message.notification!.body}',
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const ChatScreen(),
          TasksTab(key: _tasksKey),
          const DocumentsScreen(),
          LearningGraphScreen(key: _graphKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          if (i == 1) _tasksKey.currentState?.refresh();
          if (i == 3) _graphKey.currentState?.refresh();
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}

Future<void> logout(BuildContext context) async {
  await supabase.auth.signOut();
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => TasksTabState();
}

class TasksTabState extends State<TasksTab> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = false;
  bool _showCalendar = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final TtsService _tts = TtsService.instance;
  bool _isListening = false;
  bool _speechAvailable = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> _tasksForDay(DateTime day) {
    return _tasks.where((task) {
      final dueDate = task['due_date'];
      if (dueDate == null) return false;
      final parsed = DateTime.tryParse(dueDate.toString())?.toLocal();
      if (parsed == null) return false;
      return isSameDay(parsed, day);
    }).toList();
  }

  List<Map<String, dynamic>> get _displayedTasks =>
      _selectedDay == null ? _tasks : _tasksForDay(_selectedDay!);

  List<Map<String, dynamic>> get _upcomingTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = _tasks.where((task) {
      if (task['status'] != 'pending') return false;
      final dueDate = task['due_date'];
      if (dueDate == null) return false;
      final parsed = DateTime.tryParse(dueDate.toString())?.toLocal();
      if (parsed == null) return false;
      return !parsed.isBefore(today);
    }).toList();
    upcoming.sort((a, b) => a['due_date'].toString().compareTo(b['due_date'].toString()));
    return upcoming.take(10).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _initSpeech();
  }

  void refresh() => _fetchTasks();

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    setState(() {});
  }

  Future<void> _fetchTasks() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('tasks')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addTaskFromText(String text) async {
    if (text.trim().isEmpty) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('https://web-production-3f04d.up.railway.app/parse-input'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId,
        },
        body: jsonEncode({'text': text, 'user_id': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Backend error: ${response.statusCode} ${response.body}');
      }

      final parsed = jsonDecode(response.body);

      await supabase.from('tasks').insert({
        'raw_input': text,
        'title': parsed['title'] ?? text,
        'type': parsed['type'] ?? 'task',
        'due_date': parsed['due_date'],
        'status': 'pending',
        'user_id': userId,
      });

      _controller.clear();
      await _fetchTasks();

      final title = parsed['title'] ?? text;
      final dueDate = parsed['due_date'];
      final reply = dueDate != null
          ? 'Added: $title, due $dueDate'
          : 'Added: $title';
      await _tts.speak(reply);
    } catch (e) {
      debugPrint('Error adding task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      await _tts.speak('Sorry, something went wrong adding that task.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() => _isListening = false);
          _addTaskFromText(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Delete task?'),
        content: Text(task['title'] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await supabase.from('tasks').delete().eq('id', task['id']);
      await _fetchTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  String _formatDue(dynamic dueDate) {
    final parsed = DateTime.tryParse(dueDate.toString())?.toLocal();
    if (parsed == null) return '';
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  Widget _upcomingCard(Map<String, dynamic> task) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: kRed, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            task['title'] ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDue(task['due_date']),
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcomingTasks;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showCalendar = !_showCalendar),
            icon: Icon(
              _showCalendar ? Icons.calendar_month : Icons.calendar_month_outlined,
              color: _showCalendar ? kRed : null,
            ),
            tooltip: 'Toggle calendar',
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'e.g. remind me to submit DBMS assignment',
                    ),
                    onSubmitted: (_) => _addTaskFromText(_controller.text.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addTaskFromText(_controller.text.trim()),
                  child: const Text('Add'),
                ),
              ],
            ),
            if (_showCalendar) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: TableCalendar<Map<String, dynamic>>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      _selectedDay != null && isSameDay(_selectedDay, day),
                  eventLoader: _tasksForDay,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                  calendarStyle: const CalendarStyle(
                    defaultTextStyle: TextStyle(color: kTextPrimary),
                    weekendTextStyle: TextStyle(color: kTextSecondary),
                    outsideTextStyle: TextStyle(color: Color(0xFF555555)),
                    todayDecoration: BoxDecoration(
                      color: kSurfaceLight,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: kRed,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: kRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    leftChevronIcon:
                        Icon(Icons.chevron_left, color: kTextSecondary),
                    rightChevronIcon:
                        Icon(Icons.chevron_right, color: kTextSecondary),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: kTextSecondary),
                    weekendStyle: TextStyle(color: kTextSecondary),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = isSameDay(_selectedDay, selectedDay)
                          ? null
                          : selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),
            ],
            if (upcoming.isNotEmpty && _selectedDay == null) ...[
              const SizedBox(height: 24),
              const Text(
                'Coming Up',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: upcoming.map(_upcomingCard).toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDay == null
                      ? 'All Tasks'
                      : 'Tasks due ${_selectedDay!.toLocal().toString().split(' ').first}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (_selectedDay != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedDay = null),
                    child: const Text('Show all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_displayedTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No tasks yet. Add one above or ask the Assistant.',
                    style: TextStyle(color: kTextSecondary),
                  ),
                ),
              )
            else
              ..._displayedTasks.map(
                (task) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(task['title'] ?? ''),
                    subtitle: Text(
                      [
                        if (task['due_date'] != null)
                          'Due ${_formatDue(task['due_date'])}',
                        task['status'] ?? '',
                      ].join(' · '),
                      style: const TextStyle(color: kTextSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: kTextSecondary),
                      tooltip: 'Delete task',
                      onPressed: () => _deleteTask(task),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
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
