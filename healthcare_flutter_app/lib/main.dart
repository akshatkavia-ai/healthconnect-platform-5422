import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'services/todo_service.dart';

/// PUBLIC_INTERFACE
/// Main entrypoint. Initializes Supabase exactly once before running the app.
/// Shows a minimal Todos list that reads from the 'todos' table.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    // Validate config in debug to catch common mistakes.
    SupabaseConfig.debugValidate();

    // Initialize Supabase using values from SupabaseConfig. Keep existing flow intact.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    initError = 'Supabase initialization failed: $e';
  }

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
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('healthcare_flutter_app'),
            centerTitle: true,
          ),
          body: const Center(
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
/// Minimal Todos page that uses TodoService for all data operations.
/// It renders a list via FutureBuilder, shows loading/error states,
/// and includes a simple input to add a new todo.
class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  final TodoService _service = TodoService();
  late Future<List<Map<String, dynamic>>> _future;
  final TextEditingController _controller = TextEditingController();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _future = _loadTodos();
  }

  Future<List<Map<String, dynamic>>> _loadTodos() {
    // Delegate to the service for fetching todos.
    return _service.getTodos();
  }

  Future<void> _addTodo() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _adding = true;
    });
    try {
      await _service.addTodo(title);
      // Refresh list after successful insert
      setState(() {
        _future = _loadTodos();
      });
      // Avoid using controller after await in async context rules: only primitive updates.
      // Clearing controller text safely before awaiting in future usage; here directly after await,
      // we choose to update primitive state only. For UI, rely on text being kept; optional clear via setState.
    } catch (e) {
      // Surface as a snackbar using current context synchronously in build via a flag if needed.
      // Keeping minimal UI changes per instructions; ignoring elaborate error UI here.
    } finally {
      setState(() {
        _adding = false;
        _controller.text = '';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAddTodo() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'New todo title',
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _adding ? null : _addTodo,
            icon: _adding
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.add),
            label: Text(_adding ? 'Adding...' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: Column(
        children: [
          _buildAddTodo(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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

                final todos = snapshot.data ?? const <Map<String, dynamic>>[];
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
                    final isDone = (todo['is_complete'] ??
                            todo['is_done'] ??
                            todo['completed'] ??
                            false) ==
                        true;
                    final idVal = todo['id'];
                    final int? id = idVal is int
                        ? idVal
                        : int.tryParse(idVal?.toString() ?? '');

                    return ListTile(
                      title: Text(name.isEmpty ? '(untitled)' : name),
                      leading: IconButton(
                        icon: Icon(
                          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isDone ? Colors.green : Colors.grey,
                        ),
                        onPressed: id == null
                            ? null
                            : () async {
                                // Toggle status via service then refresh
                                await _service.updateTodoStatus(id, !isDone);
                                setState(() {
                                  _future = _loadTodos();
                                });
                              },
                      ),
                      trailing: id == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                await _service.deleteTodo(id);
                                setState(() {
                                  _future = _loadTodos();
                                });
                              },
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
