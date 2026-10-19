import 'package:flutter/material.dart';

import 'models/user.dart';
import 'screens/admin_dashboard.dart';
import 'screens/auth_screen.dart';
import 'screens/student_dashboard.dart';
import 'services/api_service.dart';
import 'theme/campus_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampusQuestApp());
}

class CampusQuestApp extends StatefulWidget {
  const CampusQuestApp({super.key});

  @override
  State<CampusQuestApp> createState() => _CampusQuestAppState();
}

class _CampusQuestAppState extends State<CampusQuestApp> {
  final ApiService _api = ApiService();
  User? _user;
  String? _startupError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _loading = true;
      _startupError = null;
    });
    try {
      final token = await _api.readToken();
      if (token != null && token.isNotEmpty) {
        _user = await _api.currentUser();
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _api.clearSession();
      } else {
        _startupError = error.message;
      }
    } catch (error) {
      _startupError = error.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _login(String email, String password) async {
    final user = await _api.login(email, password);
    if (mounted) {
      setState(() => _user = user);
    }
  }

  Future<void> _register(Map<String, dynamic> details) async {
    final user = await _api.registerStudent(details);
    if (mounted) {
      setState(() => _user = user);
    }
  }

  Future<void> _logout() async {
    await _api.clearSession();
    if (mounted) {
      setState(() => _user = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Quest',
      theme: buildCampusTheme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_startupError != null) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not restore your Campus Quest session.'),
                  const SizedBox(height: 8),
                  Text(_startupError!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _restoreSession,
                    child: const Text('Retry'),
                  ),
                  TextButton(onPressed: _logout, child: const Text('Sign out')),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final user = _user;
    if (user == null) {
      return AuthScreen(onLogin: _login, onRegister: _register);
    }
    if (user.isAdmin) {
      return AdminDashboard(api: _api, user: user, onLogout: _logout);
    }
    return StudentDashboard(api: _api, user: user, onLogout: _logout);
  }
}
