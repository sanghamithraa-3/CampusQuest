import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/campus_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.onLogin,
    required this.onRegister,
    super.key,
  });

  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function(Map<String, dynamic> details) onRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _rollNumber = TextEditingController();
  final _department = TextEditingController();
  final _year = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _rollNumber.dispose();
    _department.dispose();
    _year.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_registering) {
        await widget.onRegister({
          'fullName': _fullName.text.trim(),
          'rollNumber': _rollNumber.text.trim(),
          'department': _department.text.trim(),
          'yearOfStudy': int.parse(_year.text.trim()),
          'email': _email.text.trim(),
          'password': _password.text,
        });
      } else {
        await widget.onLogin(_email.text.trim(), _password.text);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1060),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (wide) const Expanded(child: _WelcomePanel()),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(wide ? 38 : 24),
                          child: _authForm(theme),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _authForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (!_registering) ...[
            const _BrandLockup(),
            const SizedBox(height: 30),
          ],
          Text(
            _registering ? 'Create your account' : 'Welcome back',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            _registering
                ? 'Start collecting the milestones that shape your story.'
                : 'Sign in to continue building your achievement portfolio.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: CampusColors.muted,
            ),
          ),
          const SizedBox(height: 24),
          if (_registering) ...[
            TextFormField(
              key: const Key('fullNameField'),
              controller: _fullName,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('rollNumberField'),
              controller: _rollNumber,
              decoration: const InputDecoration(
                labelText: 'Roll number',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('departmentField'),
              controller: _department,
              decoration: const InputDecoration(
                labelText: 'Department',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('yearField'),
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year of study (1-6)',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (value) {
                final year = int.tryParse(value ?? '');
                if (year == null || year < 1 || year > 6) {
                  return 'Enter a year from 1 to 6';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            key: const Key('emailField'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'College email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (value) {
              if (value == null ||
                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(value.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('passwordField'),
            controller: _password,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: _registering ? 'Use at least 12 characters' : null,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (_registering && value.length < 12) {
                return 'Use at least 12 characters';
              }
              if (utf8.encode(value).length > 72) {
                return 'Use no more than 72 UTF-8 bytes';
              }
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('authError'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_registering ? 'Create student account' : 'Sign in'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _registering = !_registering;
                    _error = null;
                  }),
            child: Text(
              _registering
                  ? 'Already registered? Sign in'
                  : 'New student? Create an account',
            ),
          ),
          if (!_registering)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Administrator access is provisioned by your college.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: CampusColors.lavender,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: CampusColors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'CAMPUS QUEST',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: CampusColors.navy,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 640),
      padding: const EdgeInsets.all(42),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CampusColors.navy, CampusColors.indigo],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x25FFFFFF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'CAMPUS QUEST',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(
            Icons.workspace_premium_outlined,
            size: 54,
            color: Color(0xFFDCD9F6),
          ),
          const SizedBox(height: 22),
          Text(
            'Your growth,\nbeautifully documented.',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: Colors.white, height: 1.16),
          ),
          const SizedBox(height: 14),
          Text(
            'Bring your projects, competitions and achievements together '
            'in one portfolio that reflects your journey.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: const Color(0xFFDADBED), height: 1.6),
          ),
          const Spacer(),
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: Color(0xFFDCD9F6),
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'A private space for your academic story',
                style: TextStyle(color: Color(0xFFE5E5F0)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
