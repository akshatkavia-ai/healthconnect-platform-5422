import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/theme_config.dart';
import '../config/supabase_config.dart';

/// PUBLIC_INTERFACE
class HealthCheck extends StatefulWidget {
  const HealthCheck({super.key});

  @override
  State<HealthCheck> createState() => _HealthCheckState();
}

class _HealthCheckState extends State<HealthCheck> {
  bool _checking = false;
  bool? _ok;
  String _details = '';

  String get _host {
    // Prefer the effective URL from runtime initialization, fallback to .env if not initialized.
    final effective = SupabaseConfig.effectiveSupabaseUrl;
    final url = (effective.isNotEmpty ? effective : (dotenv.env['SUPABASE_URL'] ?? '')).trim();
    if (url.isEmpty) return '(not set)';
    try {
      final uri = Uri.parse(url);
      return uri.host.isEmpty ? url : uri.host;
    } catch (_) {
      return url;
    }
  }

  Future<void> _runCheck() async {
    setState(() {
      _checking = true;
      _ok = null;
      _details = '';
    });

    final client = Supabase.instance.client;

    // Strategy: try a harmless read from a typically present table "profiles".
    // If it fails, surface the error. This is non-destructive and works even for empty tables.
    try {
      await client.from('profiles').select('id').limit(1);
      setState(() {
        _ok = true;
        _details = 'Connectivity OK: Read from profiles succeeded.';
      });
      return;
    } on PostgrestException catch (e) {
      // Permission errors are common when RLS forbids anon read.
      setState(() {
        _ok = false;
        _details = 'PostgREST error: ${e.message}\n'
            'Tip: If you see "permission denied", ensure anon role has read access or sign in first.';
      });
    } catch (e) {
      // Try an auth endpoint as a secondary signal (may fail if no session)
      try {
        await client.auth.getUser();
        setState(() {
          // If we got here, network works and user session is valid.
          _ok = true;
          _details = 'Connectivity OK via auth.getUser().';
        });
        return;
      } catch (e2) {
        setState(() {
          _ok = false;
          _details = 'Connectivity check failed.\n'
              'Primary: $e\n'
              'Auth fallback: $e2\n'
              'Tip: Verify SUPABASE_URL/SUPABASE_KEY and network access.';
        });
      }
    } finally {
      setState(() {
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _ok == null
        ? Colors.grey
        : _ok == true
            ? ThemeConfig.success
            : ThemeConfig.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Check'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Supabase Host'),
                subtitle: Text(_host),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  _ok == true
                      ? Icons.check_circle
                      : _ok == false
                          ? Icons.error
                          : Icons.help_outline,
                  color: color,
                ),
                title: const Text('Connectivity'),
                subtitle: Text(
                  _ok == null
                      ? 'Not checked'
                      : _ok == true
                          ? 'OK'
                          : 'Fail',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: _checking ? null : _runCheck,
                  icon: _checking
                      ? const SizedBox(
                          height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: Text(_checking ? 'Checking...' : 'Run'),
                ),
              ),
            ),
            if (_details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_details),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Guidance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '- Ensure .env includes SUPABASE_URL and SUPABASE_KEY.\n'
              '- If using SUPABASE_ANON_KEY, it is also supported as a fallback.\n'
              '- Verify your RLS policies allow the operation used for the check, '
              'or sign in to test with an authenticated session.',
            ),
          ],
        ),
      ),
    );
  }
}
