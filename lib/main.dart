import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const ink = Color(0xFF172A3A);
const forest = Color(0xFF176B5B);
const lime = Color(0xFFD4F16B);
const paper = Color(0xFFF5F6F2);

void main() => runApp(const CampusQuestApp());

class CampusQuestApp extends StatelessWidget {
  const CampusQuestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'CampusQuest',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: forest),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
      ),
    ),
    home: const CampusQuestRoot(),
  );
}

class QuestItem {
  QuestItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.date,
    required this.student,
    required this.points,
    this.status = 'Pending',
    this.note = '',
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String date;
  final String student;
  final int points;
  String status;
  String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'date': date,
    'student': student,
    'points': points,
    'status': status,
    'note': note,
  };

  factory QuestItem.fromJson(Map<String, dynamic> json) => QuestItem(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    description: json['description'] as String,
    date: json['date'] as String,
    student: json['student'] as String,
    points: json['points'] as int,
    status: json['status'] as String? ?? 'Pending',
    note: json['note'] as String? ?? '',
  );
}

class CampusQuestRoot extends StatefulWidget {
  const CampusQuestRoot({super.key});

  @override
  State<CampusQuestRoot> createState() => _CampusQuestRootState();
}

class _CampusQuestRootState extends State<CampusQuestRoot> {
  static const _storage = MethodChannel('campusquest/storage');
  final List<QuestItem> _items = [];
  String? _email;
  bool _faculty = false;
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.invokeMethod<String>('load');
      if (raw != null) {
        _items.addAll(
          (jsonDecode(raw) as List<dynamic>).map(
            (item) => QuestItem.fromJson(item as Map<String, dynamic>),
          ),
        );
      }
    } catch (_) {
      _items.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    await _storage.invokeMethod<void>('save', {
      'content': jsonEncode(_items.map((e) => e.toJson()).toList()),
    });
  }

  void _signIn(String email, bool faculty) => setState(() {
    _email = email;
    _faculty = faculty;
    _tab = 0;
  });

  String get _name {
    final local = (_email ?? 'explorer')
        .split('@')
        .first
        .replaceAll(RegExp(r'[._-]+'), ' ');
    return local
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_email == null) return SignInPage(onSignIn: _signIn);

    final pages = _faculty
        ? [
            FacultyPage(items: _items, onUpdate: _save),
            FacultyCommunityPage(items: _items),
            ProfilePage(
              name: _name,
              email: _email!,
              faculty: true,
              onSignOut: () => setState(() => _email = null),
            ),
          ]
        : [
            StudentHomePage(
              name: _name,
              studentEmail: _email!,
              items: _items,
              onAdd: _addAchievement,
              onTab: (tab) => setState(() => _tab = tab),
            ),
            DiscoverPage(),
            PortfolioPage(items: _items, student: _email!),
            ProfilePage(
              name: _name,
              email: _email!,
              faculty: false,
              onSignOut: () => setState(() => _email = null),
            ),
          ];
    final labels = _faculty
        ? ['Reviews', 'Students', 'Profile']
        : ['Home', 'Discover', 'Portfolio', 'Profile'];
    final icons = _faculty
        ? [
            Icons.fact_check_outlined,
            Icons.groups_2_outlined,
            Icons.person_outline,
          ]
        : [
            Icons.home_outlined,
            Icons.explore_outlined,
            Icons.workspace_premium_outlined,
            Icons.person_outline,
          ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE5F0E9),
        destinations: List.generate(
          labels.length,
          (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
        ),
      ),
    );
  }

  Future<void> _addAchievement(QuestItem item) async {
    setState(() {
      final index = _items.indexWhere((current) => current.id == item.id);
      if (index == -1) {
        _items.insert(0, item);
      } else {
        _items[index] = item;
      }
    });
    await _save();
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.onSignIn});
  final void Function(String, bool) onSignIn;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _faculty = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    widget.onSignIn(_email.text.trim().toLowerCase(), _faculty);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandMark(),
                const SizedBox(height: 42),
                Text(
                  _faculty ? 'Faculty portal' : 'Your campus,\nyour story.',
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1.08,
                    color: ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _faculty
                      ? 'Review student achievements and celebrate their progress.'
                      : 'A place for everything you do beyond the classroom.',
                  style: const TextStyle(
                    color: Color(0xFF61717A),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EBE4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _RoleChoice(
                        label: 'Student',
                        active: !_faculty,
                        onTap: () => setState(() => _faculty = false),
                      ),
                      _RoleChoice(
                        label: 'Faculty',
                        active: _faculty,
                        onTap: () => setState(() => _faculty = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'College email',
                          prefixIcon: Icon(Icons.mail_outline),
                          hintText: 'you@college.edu',
                        ),
                        validator: (v) =>
                            v == null ||
                                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(v.trim())
                            ? 'Enter a valid college email'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6
                            ? 'Use at least 6 characters'
                            : null,
                      ),
                    ],
                  ),
                ),
                if (_faculty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Faculty access is assigned by your campus administrator.',
                      style: TextStyle(color: Color(0xFF66747C), fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: ink,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _faculty ? 'Continue as faculty' : 'Continue with email',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'DEMO MODE  ·  Data stays on this device',
                    style: TextStyle(
                      color: Color(0xFF89949A),
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 6,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? ink : const Color(0xFF78837E),
            ),
          ),
        ),
      ),
    ),
  );
}

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({
    super.key,
    required this.name,
    required this.studentEmail,
    required this.items,
    required this.onAdd,
    required this.onTab,
  });
  final String name, studentEmail;
  final List<QuestItem> items;
  final Future<void> Function(QuestItem) onAdd;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final own = items.where((item) => item.student == studentEmail).toList();
    final approved = own.where((item) => item.status == 'Approved').toList();
    final pending = own.where((item) => item.status == 'Pending').length;
    final submissions = own
        .where((item) => item.status != 'Approved')
        .take(5)
        .toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  const BrandMark(compact: true),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE5EEE9),
                    child: Text(
                      name.isEmpty ? 'S' : name[0],
                      style: const TextStyle(
                        color: forest,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'HEY, ${name.split(' ').first.toUpperCase()} 👋',
                style: const TextStyle(
                  color: forest,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make this year\ncount.',
                style: TextStyle(
                  color: ink,
                  fontSize: 34,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 20),
              _HighlightCard(
                points: approved.fold<int>(0, (sum, item) => sum + item.points),
                approved: approved.length,
                pending: pending,
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: _SectionHeading(
                      'Your journey',
                      'Every experience adds up',
                    ),
                  ),
                  TextButton(
                    onPressed: () => onTab(2),
                    child: const Text('See portfolio'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Approved',
                      number: '${approved.length}',
                      icon: Icons.verified_outlined,
                      color: const Color(0xFFE7F1E9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'In review',
                      number: '$pending',
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFFFFF2D9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'XP earned',
                      number:
                          '${approved.fold<int>(0, (sum, item) => sum + item.points)}',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFF0E8FC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 27),
              Row(
                children: [
                  const Expanded(
                    child: _SectionHeading(
                      'Keep exploring',
                      'Find your next opportunity',
                    ),
                  ),
                  TextButton(
                    onPressed: () => onTab(1),
                    child: const Text('Explore all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _OpportunityCard(
                icon: Icons.groups_2_outlined,
                color: const Color(0xFFE8F1EA),
                title: 'Find your people',
                subtitle: 'Discover clubs and communities',
                onTap: () => onTab(1),
              ),
              const SizedBox(height: 10),
              _OpportunityCard(
                icon: Icons.emoji_events_outlined,
                color: const Color(0xFFFFF1D8),
                title: 'Try a new challenge',
                subtitle: 'Turn campus moments into quests',
                onTap: () => onTab(1),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  const Expanded(
                    child: _SectionHeading(
                      'Recent activity',
                      'Your latest submissions',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openAdd(context, studentEmail, onAdd),
                    child: const Text('+ Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (submissions.isEmpty)
                _EmptyCard(onTap: () => _openAdd(context, studentEmail, onAdd))
              else
                ...submissions.map(
                  (item) => _AchievementTile(
                    item: item,
                    onResubmit: item.status == 'Changes needed'
                        ? () => _openAdd(
                            context,
                            studentEmail,
                            onAdd,
                            existing: item,
                          )
                        : null,
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.points,
    required this.approved,
    required this.pending,
  });
  final int points, approved, pending;
  @override
  Widget build(BuildContext context) {
    final level = points ~/ 100 + 1;
    final levelProgress = points % 100;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF163444), Color(0xFF176B5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: lime, size: 18),
              const SizedBox(width: 8),
              const Text(
                'YOUR CAMPUS STORY',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pending waiting',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$points XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$approved achievements approved',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: levelProgress / 100,
              minHeight: 7,
              backgroundColor: Color(0x553FFFFFF),
              color: lime,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'LEVEL $level · EXPLORER',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Spacer(),
              Text(
                '$levelProgress / 100 XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF79868C), fontSize: 11),
      ),
    ],
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
  });
  final String label, number;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: ink),
        ),
        const SizedBox(height: 12),
        Text(
          number,
          style: const TextStyle(
            fontSize: 20,
            color: ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: Color(0xFF78848B)),
        ),
      ],
    ),
  );
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: forest),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF79868C),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF8A969A),
            ),
          ],
        ),
      ),
    ),
  );
}

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String _filter = 'All';
  final _filters = const ['All', 'Clubs', 'Events', 'Volunteering', 'Learning'];
  @override
  Widget build(BuildContext context) {
    final quests = [
      (
        'Clubs',
        'Meet a new community',
        'Visit a club meetup and find your people.',
        Icons.diversity_3_outlined,
        '50 XP',
        'This week',
      ),
      (
        'Events',
        'Show up for a campus event',
        'Attend a talk, cultural event or showcase.',
        Icons.event_available_outlined,
        '40 XP',
        'Anytime',
      ),
      (
        'Volunteering',
        'Give an hour back',
        'Join a campus or community service activity.',
        Icons.volunteer_activism_outlined,
        '80 XP',
        'This month',
      ),
      (
        'Learning',
        'Learn beyond your lecture',
        'Complete a workshop or short course.',
        Icons.lightbulb_outline,
        '60 XP',
        'Anytime',
      ),
      (
        'Events',
        'Represent your department',
        'Take part in an inter-department event.',
        Icons.flag_outlined,
        '100 XP',
        'This semester',
      ),
    ];
    final filtered = _filter == 'All'
        ? quests
        : quests.where((quest) => quest.$1 == _filter).toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const BrandMark(compact: true),
              const SizedBox(height: 27),
              const _SectionHeading(
                'Explore quests',
                'Small steps make a big campus story.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filters
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: f == _filter,
                            onSelected: (_) => setState(() => _filter = f),
                            selectedColor: const Color(0xFFDCEBE2),
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                            labelStyle: TextStyle(
                              color: f == _filter
                                  ? forest
                                  : const Color(0xFF77838A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 19),
              ...filtered.map(
                (q) => _QuestCard(
                  category: q.$1,
                  title: q.$2,
                  description: q.$3,
                  icon: q.$4,
                  points: q.$5,
                  timing: q.$6,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFEA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: forest),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Completed something else? Add it to your portfolio for faculty review.',
                        style: TextStyle(
                          color: ink,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.timing,
  });
  final String category, title, description, points, timing;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2EC),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: forest),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF68767A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: const TextStyle(
            color: Color(0xFF77848A),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFC28A18), size: 16),
            Text(
              points,
              style: const TextStyle(
                color: ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.schedule, color: Color(0xFF89949A), size: 14),
            const SizedBox(width: 4),
            Text(
              timing,
              style: const TextStyle(color: Color(0xFF89949A), fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );
}

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key, required this.items, required this.student});
  final List<QuestItem> items;
  final String student;
  @override
  Widget build(BuildContext context) {
    final approved = items
        .where((item) => item.student == student && item.status == 'Approved')
        .toList();
    final points = approved.fold<int>(0, (sum, item) => sum + item.points);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const BrandMark(compact: true),
              const SizedBox(height: 27),
              const _SectionHeading(
                'Your portfolio',
                'A collection of what you have done.',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EFE8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        color: forest,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${approved.length} approved achievements',
                            style: const TextStyle(
                              color: ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$points experience points',
                            style: const TextStyle(
                              color: Color(0xFF708078),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'APPROVED ACHIEVEMENTS',
                style: TextStyle(
                  color: Color(0xFF7A8985),
                  fontSize: 10,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 11),
              if (approved.isEmpty)
                const _PortfolioEmpty()
              else
                ...approved.map((item) => _AchievementTile(item: item)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _PortfolioEmpty extends StatelessWidget {
  const _PortfolioEmpty();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(Icons.auto_awesome_outlined, color: forest, size: 29),
        SizedBox(height: 12),
        Text(
          'Your story is getting started',
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          'Achievements appear here after faculty approval.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF78858B), fontSize: 12, height: 1.5),
        ),
      ],
    ),
  );
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.item, this.onResubmit});
  final QuestItem item;
  final VoidCallback? onResubmit;
  @override
  Widget build(BuildContext context) {
    final approved = item.status == 'Approved';
    final rejected = item.status == 'Changes needed';
    final color = approved
        ? forest
        : rejected
        ? const Color(0xFFB45746)
        : const Color(0xFFA3771F);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: approved
                      ? const Color(0xFFE9F2EB)
                      : const Color(0xFFFFF4DE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(item.category), size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} · ${item.date}',
                      style: const TextStyle(
                        color: Color(0xFF849096),
                        fontSize: 10,
                      ),
                    ),
                    if (item.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          item.note,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${item.points} XP',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.status,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onResubmit != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: onResubmit,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Update and resubmit'),
                style: TextButton.styleFrom(
                  foregroundColor: forest,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

IconData _iconFor(String category) => switch (category) {
  'Events' => Icons.event_outlined,
  'Volunteering' => Icons.volunteer_activism_outlined,
  'Learning' => Icons.menu_book_outlined,
  'Sports' => Icons.sports_basketball_outlined,
  _ => Icons.diversity_3_outlined,
};

class FacultyPage extends StatefulWidget {
  const FacultyPage({super.key, required this.items, required this.onUpdate});
  final List<QuestItem> items;
  final Future<void> Function() onUpdate;

  @override
  State<FacultyPage> createState() => _FacultyPageState();
}

class _FacultyPageState extends State<FacultyPage> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final pending = widget.items
        .where(
          (item) =>
              item.status == 'Pending' &&
              (_category == 'All' || item.category == _category),
        )
        .toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const BrandMark(compact: true),
              const SizedBox(height: 27),
              const _SectionHeading(
                'Review achievements',
                'Assigned submissions for your categories.',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fact_check_outlined,
                      color: lime,
                      size: 28,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pending.length} waiting for review',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Review submissions and award XP.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      [
                            'All',
                            'Events',
                            'Clubs',
                            'Volunteering',
                            'Learning',
                            'Sports',
                            'Leadership',
                          ]
                          .map(
                            (category) => Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: _category == category,
                                onSelected: (_) =>
                                    setState(() => _category = category),
                                selectedColor: const Color(0xFFDCEBE2),
                                backgroundColor: Colors.white,
                                side: BorderSide.none,
                                labelStyle: TextStyle(
                                  color: _category == category
                                      ? forest
                                      : const Color(0xFF77838A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'PENDING SUBMISSIONS',
                style: TextStyle(
                  color: Color(0xFF7A8985),
                  fontSize: 10,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 11),
              if (pending.isEmpty)
                const _NoReviews()
              else
                ...pending.map(
                  (item) => _ReviewCard(
                    item: item,
                    onReview: (approve, note) async {
                      item.status = approve ? 'Approved' : 'Changes needed';
                      item.note = note;
                      await widget.onUpdate();
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              approve
                                  ? 'Achievement approved.'
                                  : 'Feedback sent to student.',
                            ),
                          ),
                        );
                    },
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item, required this.onReview});
  final QuestItem item;
  final Future<void> Function(bool, String) onReview;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFE5EFE8),
              child: Text(
                item.student.isEmpty ? '?' : item.student[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  color: forest,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                item.student,
                style: const TextStyle(
                  color: ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              item.date,
              style: const TextStyle(color: Color(0xFF849096), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          item.title,
          style: const TextStyle(
            color: ink,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.category,
          style: const TextStyle(
            color: forest,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          item.description,
          style: const TextStyle(
            color: Color(0xFF728086),
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.bolt, size: 15, color: Color(0xFFC28A18)),
            const SizedBox(width: 4),
            Text(
              'Suggested reward: ${item.points} XP',
              style: const TextStyle(color: Color(0xFF849096), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showReview(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45746),
                  side: const BorderSide(color: Color(0xFFEBD6D0)),
                ),
                child: const Text('Request changes'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => onReview(true, ''),
                style: FilledButton.styleFrom(
                  backgroundColor: forest,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  void _showReview(BuildContext context, bool approve) {
    final note = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request an update'),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Tell the student what to add or clarify.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onReview(
                approve,
                note.text.trim().isEmpty
                    ? 'Please add more detail or evidence.'
                    : note.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Send feedback'),
          ),
        ],
      ),
    );
  }
}

class _NoReviews extends StatelessWidget {
  const _NoReviews();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(Icons.task_alt, size: 30, color: forest),
        SizedBox(height: 11),
        Text(
          'All caught up',
          style: TextStyle(color: ink, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'New student submissions will appear here.',
          style: TextStyle(color: Color(0xFF78858B), fontSize: 12),
        ),
      ],
    ),
  );
}

class FacultyCommunityPage extends StatelessWidget {
  const FacultyCommunityPage({super.key, required this.items});
  final List<QuestItem> items;
  @override
  Widget build(BuildContext context) {
    final grouped = <String, int>{};
    for (final item in items) {
      grouped[item.student] = (grouped[item.student] ?? 0) + 1;
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const BrandMark(compact: true),
              const SizedBox(height: 27),
              const _SectionHeading(
                'Student activity',
                'Submissions in your review queue.',
              ),
              const SizedBox(height: 18),
              if (grouped.isEmpty)
                const _NoReviews()
              else
                ...grouped.entries.map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE6EFE9),
                          child: Text(
                            entry.key.isEmpty
                                ? '?'
                                : entry.key[0].toUpperCase(),
                            style: const TextStyle(
                              color: forest,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${entry.value} submission${entry.value == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: Color(0xFF849096),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF849096),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Faculty accounts and assigned student categories are managed by the campus administrator.',
                style: TextStyle(
                  color: Color(0xFF76848A),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.faculty,
    required this.onSignOut,
  });
  final String name, email;
  final bool faculty;
  final VoidCallback onSignOut;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
    children: [
      const BrandMark(compact: true),
      const SizedBox(height: 28),
      const _SectionHeading('Your profile', 'Account details and preferences.'),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 33,
              backgroundColor: const Color(0xFFE4EEE8),
              child: Text(
                name.isEmpty ? 'S' : name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 25,
                  color: forest,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 13),
            Text(
              name,
              style: const TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(color: Color(0xFF78858B), fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F2EB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                faculty ? 'Faculty reviewer' : 'Student explorer',
                style: const TextStyle(
                  color: forest,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _SettingsRow(
        icon: Icons.school_outlined,
        title: 'Thiagarajar College of Engineering',
        subtitle: 'Campus',
      ),
      _SettingsRow(
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy',
        subtitle: 'Approved achievements appear in your portfolio',
      ),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: onSignOut,
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          padding: const EdgeInsets.all(14),
        ),
      ),
    ],
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(icon, color: forest),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF859097), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: forest),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add your first achievement',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share something you did on campus.',
                    style: TextStyle(color: Color(0xFF7E8A90), fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8A969A)),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openAdd(
  BuildContext context,
  String studentEmail,
  Future<void> Function(QuestItem) onSave, {
  QuestItem? existing,
}) async {
  final result = await showModalBottomSheet<QuestItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _AddAchievementSheet(student: studentEmail, existing: existing),
  );
  if (result != null) {
    await onSave(result);
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Achievement submitted for faculty review.'),
        ),
      );
  }
}

class _AddAchievementSheet extends StatefulWidget {
  const _AddAchievementSheet({required this.student, this.existing});
  final String student;
  final QuestItem? existing;
  @override
  State<_AddAchievementSheet> createState() => _AddAchievementSheetState();
}

class _AddAchievementSheetState extends State<_AddAchievementSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Events';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _title.text = existing.title;
      _description.text = existing.description;
      _category = existing.category;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: 80,
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Container(
      padding: const EdgeInsets.fromLTRB(21, 22, 21, 26),
      decoration: const BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCDD4CE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.existing == null
                      ? 'Add an achievement'
                      : 'Update achievement',
                  style: TextStyle(
                    color: ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Your faculty reviewer will check this before it appears in your portfolio.',
                  style: TextStyle(
                    color: Color(0xFF77848A),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 17),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'What did you do?',
                    hintText: 'e.g. Presented a project at TechFest',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Add a title' : null,
                ),
                const SizedBox(height: 13),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      [
                            'Events',
                            'Clubs',
                            'Volunteering',
                            'Learning',
                            'Sports',
                            'Leadership',
                          ]
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'Events'),
                ),
                const SizedBox(height: 13),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'A few details',
                    hintText: 'What did you learn or contribute?',
                  ),
                  validator: (v) => v == null || v.trim().length < 8
                      ? 'Add a little more detail'
                      : null,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.attach_file, color: forest),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Evidence upload can be connected to campus storage.',
                          style: TextStyle(
                            color: Color(0xFF7A878D),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 51,
                  child: FilledButton(
                    onPressed: () {
                      if (!_form.currentState!.validate()) return;
                      final points = switch (_category) {
                        'Volunteering' => 80,
                        'Learning' => 60,
                        'Sports' => 70,
                        'Leadership' => 100,
                        'Clubs' => 50,
                        _ => 40,
                      };
                      Navigator.pop(
                        context,
                        QuestItem(
                          id:
                              widget.existing?.id ??
                              DateTime.now().microsecondsSinceEpoch.toString(),
                          title: _title.text.trim(),
                          category: _category,
                          description: _description.text.trim(),
                          date: DateTime.now()
                              .toLocal()
                              .toString()
                              .split(' ')
                              .first,
                          student: widget.student,
                          points: points,
                          note: '',
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ink,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      widget.existing == null
                          ? 'Submit for review'
                          : 'Send updated version',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 31,
        height: 31,
        decoration: BoxDecoration(
          color: forest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Icon(Icons.explore, color: lime, size: 19)),
      ),
      const SizedBox(width: 9),
      Text(
        compact ? 'campusquest' : 'CampusQuest',
        style: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: -.4,
        ),
      ),
    ],
  );
}
