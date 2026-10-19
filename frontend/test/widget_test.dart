import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/screens/auth_screen.dart';
import 'package:frontend/models/achievement.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/screens/admin_dashboard.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/screens/student_dashboard.dart';

void main() {
  testWidgets('sign-in offers student registration without role selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          onLogin: (email, password) async {},
          onAdminLogin: (email, password) async {},
          onRegister: (details) async {},
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('adminLoginOption')), findsOneWidget);

    await tester.tap(find.byKey(const Key('adminLoginOption')));
    await tester.pumpAndSettle();
    expect(find.text('Admin login'), findsOneWidget);
    expect(find.byKey(const Key('backToStudentLogin')), findsOneWidget);
    expect(find.text('New student? Create an account'), findsNothing);

    await tester.tap(find.byKey(const Key('backToStudentLogin')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New student? Create an account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.byKey(const Key('fullNameField')), findsOneWidget);
    expect(find.byKey(const Key('rollNumberField')), findsOneWidget);
    expect(find.byKey(const Key('departmentField')), findsOneWidget);
    expect(find.byKey(const Key('yearField')), findsOneWidget);
    expect(find.byKey(const Key('adminLoginOption')), findsNothing);
  });

  testWidgets('admin login submits to its dedicated callback', (tester) async {
    var studentLoginCalled = false;
    var adminLoginEmail = '';

    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          onLogin: (email, password) async {
            studentLoginCalled = true;
          },
          onAdminLogin: (email, password) async {
            adminLoginEmail = email;
          },
          onRegister: (details) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adminLoginOption')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('emailField')),
      'admin@example.edu',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'administrator-password',
    );
    await tester.tap(find.text('Sign in as administrator'));
    await tester.pumpAndSettle();

    expect(adminLoginEmail, 'admin@example.edu');
    expect(studentLoginCalled, isFalse);
    expect(find.text('Admin login'), findsOneWidget);
  });

  testWidgets('desktop authentication panel has bounded scroll layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          onLogin: (email, password) async {},
          onAdminLogin: (email, password) async {},
          onRegister: (details) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('New student? Create an account'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('fullNameField')), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('student overview adapts navigation on mobile and desktop', (
    tester,
  ) async {
    final api = _FakeApiService();
    const user = User(
      id: 'student-1',
      fullName: 'Asha Raman',
      email: 'asha@example.edu',
      role: 'student',
      rollNumber: 'TCE123',
      department: 'Computer Science',
      yearOfStudy: 2,
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: StudentDashboard(api: api, user: user, onLogout: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Asha'), findsOneWidget);
    expect(find.text('Your story starts here'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Achievements'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('admin can search student accounts in the desktop table', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    final api = _FakeApiService(
      studentsResponse: const [
        User(
          id: 'student-1',
          fullName: 'Asha Raman',
          email: 'asha@example.edu',
          role: 'student',
          rollNumber: 'TCE123',
          department: 'Computer Science',
          yearOfStudy: 2,
        ),
        User(
          id: 'student-2',
          fullName: 'Nila Kumar',
          email: 'nila@example.edu',
          role: 'student',
          rollNumber: 'TCE999',
          department: 'Information Technology',
          yearOfStudy: 3,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: AdminDashboard(
          api: api,
          user: const User(
            id: 'admin-1',
            fullName: 'Administrator',
            email: 'admin@example.edu',
            role: 'admin',
          ),
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Asha Raman'), findsOneWidget);
    expect(find.text('Nila Kumar'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'TCE999');
    await tester.pumpAndSettle();

    expect(find.text('Nila Kumar'), findsOneWidget);
    expect(find.text('Asha Raman'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}

class _FakeApiService extends ApiService {
  _FakeApiService({this.studentsResponse = const []})
    : super(
        client: MockClient((_) async => http.Response('{}', 200)),
        baseUrl: 'http://localhost:5000/api',
      );

  final List<User> studentsResponse;

  @override
  Future<List<Achievement>> myAchievements() async => [];

  @override
  Future<List<User>> students() async => studentsResponse;

  @override
  Future<List<Achievement>> allAchievements() async => [];

  @override
  Future<Map<String, dynamic>> portfolio({String? studentId}) async => {
    'success': true,
    'portfolio': {'achievements': <dynamic>[]},
  };
}
