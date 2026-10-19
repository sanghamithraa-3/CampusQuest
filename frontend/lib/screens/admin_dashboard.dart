import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/campus_theme.dart';
import '../widgets/achievement_card.dart';
import '../widgets/responsive_shell.dart';
import 'achievement_form_dialog.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    required this.api,
    required this.user,
    required this.onLogout,
    super.key,
  });

  final ApiService api;
  final User user;
  final VoidCallback onLogout;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const _destinations = [
    CampusDestination(
      label: 'Students',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
    ),
    CampusDestination(
      label: 'Achievements',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium_rounded,
    ),
  ];

  final _searchController = TextEditingController();
  List<User> _students = [];
  List<Achievement> _achievements = [];
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;
  String _studentFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        widget.api.students(),
        widget.api.allAchievements(),
      ]);
      if (mounted) {
        setState(() {
          _students = result[0] as List<User>;
          _achievements = result[1] as List<Achievement>;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _setActive(User student, bool isActive) async {
    final action = isActive ? 'reactivate' : 'deactivate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isActive ? 'Reactivate' : 'Deactivate'} student?'),
        content: Text(
          'This will $action ${student.fullName}\'s account. '
          'Their achievements will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isActive ? 'Reactivate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.api.setStudentActive(student.id, isActive);
      await _load();
    } catch (error) {
      if (mounted) {
        _message(error.toString(), isError: true);
      }
    }
  }

  Future<void> _editAchievement(Achievement achievement) async {
    final details = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AchievementFormDialog(achievement: achievement),
    );
    if (details == null) {
      return;
    }
    try {
      await widget.api.updateAchievement(achievement.id, details);
      await _load();
      if (mounted) {
        _message('Achievement updated');
      }
    } catch (error) {
      if (mounted) {
        _message(error.toString(), isError: true);
      }
    }
  }

  Future<void> _deleteAchievement(Achievement achievement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete achievement?'),
        content: Text(
          'Delete "${achievement.title}" from '
          '${achievement.studentName ?? 'the student'}\'s portfolio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await widget.api.deleteAchievement(achievement.id, asAdmin: true);
      await _load();
      if (mounted) {
        _message('Achievement deleted');
      }
    } catch (error) {
      if (mounted) {
        _message(error.toString(), isError: true);
      }
    }
  }

  Future<void> _showPortfolio(User student) async {
    try {
      final response = await widget.api.portfolio(studentId: student.id);
      if (!mounted) {
        return;
      }
      final portfolio = response['portfolio'] as Map<String, dynamic>;
      final achievements = (portfolio['achievements'] as List<dynamic>)
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${student.fullName}\'s portfolio'),
          content: SizedBox(
            width: 680,
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student.rollNumber} · ${student.department} · '
                  'Year ${student.yearOfStudy}',
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: achievements.isEmpty
                      ? const Center(child: Text('No achievements submitted'))
                      : ListView.separated(
                          itemCount: achievements.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => AchievementCard(
                            achievement: achievements[index],
                            dense: true,
                          ),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                try {
                  await widget.api.downloadPortfolio(
                    studentId: student.id,
                    filename: 'campus-quest-${student.rollNumber}',
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _message('Portfolio PDF downloaded');
                  }
                } catch (error) {
                  if (context.mounted) {
                    _message(error.toString(), isError: true);
                  }
                }
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download PDF'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        _message(error.toString(), isError: true);
      }
    }
  }

  void _message(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      title: 'Administrator workspace',
      destinations: _destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
          _searchController.clear();
        });
      },
      onLogout: widget.onLogout,
      actions: [
        IconButton(
          tooltip: 'Refresh data',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: _content(),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: CampusColors.indigo,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                'Workspace could not be loaded',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = constraints.maxWidth < 600 ? 18.0 : 36.0;
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(inset, 18, inset, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _welcome(context),
                      const SizedBox(height: 20),
                      _summaryCards(context, constraints.maxWidth),
                      const SizedBox(height: 26),
                      _sectionHeader(
                        _selectedIndex == 0
                            ? 'Student accounts'
                            : 'Achievement records',
                      ),
                      const SizedBox(height: 12),
                      _searchField(),
                      const SizedBox(height: 12),
                      if (_selectedIndex == 0) ...[
                        _studentFilters(),
                        const SizedBox(height: 12),
                        _studentsContent(constraints.maxWidth),
                      ] else
                        _achievementsContent(constraints.maxWidth),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _welcome(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: CampusColors.navy,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAMPUS QUEST · ADMINISTRATION',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFD8D8F1),
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Good to see you, ${widget.user.fullName}',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage student access and keep achievement records organized.',
                  style: TextStyle(color: Color(0xFFE0E0F0)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.admin_panel_settings_outlined,
            color: Color(0xFFDCD9F6),
            size: 44,
          ),
        ],
      ),
    );
  }

  Widget _summaryCards(BuildContext context, double width) {
    final cards = [
      _AdminStat(
        label: 'Student accounts',
        value: '${_students.length}',
        icon: Icons.people_outline_rounded,
        tint: CampusColors.lavender,
      ),
      _AdminStat(
        label: 'Active students',
        value: '${_students.where((student) => student.isActive).length}',
        icon: Icons.check_circle_outline_rounded,
        tint: CampusColors.mint,
      ),
      _AdminStat(
        label: 'Achievements',
        value: '${_achievements.length}',
        icon: Icons.workspace_premium_outlined,
        tint: CampusColors.amber,
      ),
    ];
    if (width < 760) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: card,
              ),
            )
            .toList(),
      );
    }
    return Row(
      children: cards
          .map(
            (card) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: card,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _sectionHeader(String title) {
    final count = _selectedIndex == 0 ? _students.length : _achievements.length;
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text('$count total', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: _selectedIndex == 0
            ? 'Search by name, roll number or email'
            : 'Search by title, category or student',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }

  Widget _studentFilters() {
    return Wrap(
      spacing: 8,
      children: ['All', 'Active', 'Inactive']
          .map(
            (filter) => ChoiceChip(
              label: Text(filter),
              selected: _studentFilter == filter,
              onSelected: (_) => setState(() => _studentFilter = filter),
            ),
          )
          .toList(),
    );
  }

  List<User> get _visibleStudents {
    final query = _searchController.text.trim().toLowerCase();
    return _students.where((student) {
      final matchesFilter = switch (_studentFilter) {
        'Active' => student.isActive,
        'Inactive' => !student.isActive,
        _ => true,
      };
      final matchesSearch =
          query.isEmpty ||
          [
            student.fullName,
            student.email,
            student.rollNumber ?? '',
            student.department ?? '',
          ].any((field) => field.toLowerCase().contains(query));
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<Achievement> get _visibleAchievements {
    final query = _searchController.text.trim().toLowerCase();
    return _achievements.where((achievement) {
      return query.isEmpty ||
          [
            achievement.title,
            achievement.category,
            achievement.studentName ?? '',
          ].any((field) => field.toLowerCase().contains(query));
    }).toList();
  }

  Widget _studentsContent(double width) {
    final students = _visibleStudents;
    if (students.isEmpty) {
      return _emptyPanel(
        'No matching students',
        'Try a different search or account filter.',
      );
    }
    if (width >= 1000) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Student')),
              DataColumn(label: Text('Roll number')),
              DataColumn(label: Text('Department')),
              DataColumn(label: Text('Year')),
              DataColumn(label: Text('Account')),
              DataColumn(label: Text('Portfolio')),
            ],
            rows: students
                .map(
                  (student) => DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                student.email,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text(student.rollNumber ?? '—')),
                      DataCell(Text(student.department ?? '—')),
                      DataCell(Text('${student.yearOfStudy ?? '—'}')),
                      DataCell(
                        Switch(
                          value: student.isActive,
                          onChanged: (value) => _setActive(student, value),
                        ),
                      ),
                      DataCell(
                        OutlinedButton.icon(
                          onPressed: () => _showPortfolio(student),
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('View / PDF'),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      );
    }
    return Column(
      children: students
          .map(
            (student) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StudentCard(
                student: student,
                onActiveChanged: (value) => _setActive(student, value),
                onPortfolio: () => _showPortfolio(student),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _achievementsContent(double width) {
    final achievements = _visibleAchievements;
    if (achievements.isEmpty) {
      return _emptyPanel(
        'No matching achievements',
        'Try a different title, category or student name.',
      );
    }
    if (width >= 1050) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: achievements.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 540,
          mainAxisExtent: 235,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (context, index) =>
            _adminAchievementCard(achievements[index]),
      );
    }
    return Column(
      children: achievements
          .map(
            (achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _adminAchievementCard(achievement),
            ),
          )
          .toList(),
    );
  }

  Widget _adminAchievementCard(Achievement achievement) {
    return AchievementCard(
      achievement: achievement,
      showStudent: true,
      dense: true,
      actions: [
        IconButton(
          tooltip: 'Edit achievement',
          onPressed: () => _editAchievement(achievement),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete achievement',
          onPressed: () => _deleteAchievement(achievement),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }

  Widget _emptyPanel(String title, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: CampusColors.indigo,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  const _AdminStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: CampusColors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onActiveChanged,
    required this.onPortfolio,
  });

  final User student;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onPortfolio;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: CampusColors.lavender,
                  foregroundColor: CampusColors.indigo,
                  child: Text(
                    student.fullName.isEmpty
                        ? '?'
                        : student.fullName[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        student.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(value: student.isActive, onChanged: onActiveChanged),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${student.rollNumber ?? 'No roll number'} · '
              '${student.department ?? 'No department'} · '
              'Year ${student.yearOfStudy ?? '—'}',
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onPortfolio,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('View portfolio / PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
