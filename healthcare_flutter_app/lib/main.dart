import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// PUBLIC_INTERFACE
/// Main entrypoint. Initializes Supabase exactly once before running the app.
/// Shows a minimal Todos list that reads from the 'todos' table (expects a text column 'name').
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    // Validate config in debug to catch common mistakes.
    SupabaseConfig.debugValidate();

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    initError = 'Supabase initialization failed: $e';
  }

  // Use placeholder=false to render the real app. If initialization failed,
  // an error page is shown inside MyApp.
  runApp(MyApp(
    showPlaceholder: false,
    initError: initError,
  ));
}

/// PUBLIC_INTERFACE
/// Root widget. Defaults to a simple placeholder to allow quick widget tests
/// to instantiate `const MyApp()` without running the async initialization.
class MyApp extends StatelessWidget {
  final bool showPlaceholder;
  final String? initError;

  const MyApp({
    super.key,
    this.showPlaceholder = true,
    this.initError,
  });

  @override
  Widget build(BuildContext context) {
    if (showPlaceholder) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('healthcare_flutter_app App is being generated...'),
              ],
            ),
          ),
        ),
      );
    }

    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Supabase Init Error',
        home: _InitErrorScreen(message: initError!),
      );
    }

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todos',
      home: TodosPage(),
    );
  }
}

class _InitErrorScreen extends StatelessWidget {
  final String message;
  const _InitErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration Required')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text(
                  'Supabase Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How to fix',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  '- Provide your project credentials via --dart-define:\n'
                  '  flutter run \\\n'
                  '    --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\\n'
                  '    --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY\n\n'
                  '- Or update the fallbacks in lib/supabase_config.dart (development only).',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// PUBLIC_INTERFACE
/// Minimal Todos page that reads from the 'todos' table and displays each row's 'name' field.
/// Add a text column 'name' in your Supabase project's `todos` table and ensure RLS allows anon read if testing unauthenticated.
class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  late final Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchTodos();
  }

  Future<List<Map<String, dynamic>>> _fetchTodos() async {
    final client = Supabase.instance.client;
    final rows = await client
        .from('todos')
        .select<List<Map<String, dynamic>>>()
        .order('id', ascending: true);
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: FutureBuilder<List<Map<String, dynamic>>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading todos: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final todos = snapshot.data ?? <Map<String, dynamic>>[];
          if (todos.isEmpty) {
            return const Center(child: Text('No todos found'));
          }
          return ListView.separated(
            itemCount: todos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final todo = todos[index];
              final name =
                  (todo['name'] ?? todo['title'] ?? '').toString().trim();
              final isDone = (todo['is_complete'] ?? todo['completed'] ?? false) == true;
              return ListTile(
                title: Text(name.isEmpty ? '(untitled)' : name),
                leading: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone ? Colors.green : Colors.grey,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
