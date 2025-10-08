import 'package:supabase_flutter/supabase_flutter.dart';

/// PUBLIC_INTERFACE
/// Service for basic CRUD operations on the 'todos' table using Supabase.
class TodoService {
  final SupabaseClient _client = Supabase.instance.client;

  /// PUBLIC_INTERFACE
  /// Fetch all todos as a list of map rows.
  Future<List<Map<String, dynamic>>> getTodos() async {
    // In supabase_flutter v2, queries are awaitable directly and return JSON.
    final data = await _client.from('todos').select();
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// PUBLIC_INTERFACE
  /// Add a new todo with the given title.
  Future<void> addTodo(String title) async {
    await _client.from('todos').insert({'title': title});
  }

  /// PUBLIC_INTERFACE
  /// Update the 'is_done' status for a todo by id.
  Future<void> updateTodoStatus(int id, bool isDone) async {
    await _client
        .from('todos')
        .update({'is_done': isDone})
        .eq('id', id);
  }

  /// PUBLIC_INTERFACE
  /// Delete a todo by id.
  Future<void> deleteTodo(int id) async {
    await _client.from('todos').delete().eq('id', id);
  }
}
