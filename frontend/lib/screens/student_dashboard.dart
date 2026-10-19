import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/campus_theme.dart';
import '../widgets/achievement_card.dart';
import '../widgets/responsive_shell.dart';
import 'achievement_form_dialog.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({
    required this.api,
    required this.user,
    required this.onLogout,
    super.key,
  });

  final ApiService api;
  final User user;
  final VoidCallback onLogout;

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  static const _destinations = [
    CampusDestination(
      label: 'Overview',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    CampusDestination(
      label: 'Achievements',
      icon: Icons.workspace_premium_outlined,
      selectedIcon: Icons.workspace_premium_rounded,
    ),
    CampusDestination(
      label: 'My portfolio',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
    ),
  ];

  List<Achievement> _achievements = [];
  bool _loading = true;
  String? _error;
  bool _working = false;
  int _selectedIndex = 0;
  bool _portfolioLoading = false;
  String? _portfolioError;
  List<Achievement>? _portfolioAchievements;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final achievements = await widget.api.myAchievements();
      if (mounted) {
        setState(() {
          _achievements = achievements;
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

  Future<void> _loadPortfolio() async {
    setState(() {
      _portfolioLoading = true;
      _portfolioError = null;
    });
    try {
      final response = await widget.api.portfolio();
      final portfolio = response['portfolio'] as Map<String, dynamic>;
      final achievements = (portfolio['achievements'] as List<dynamic>)
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _portfolioAchievements = achievements;
          _portfolioLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _portfolioError = error.toString();
          _portfolioLoading = false;
        });
      }
    }
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
    if (index == 2 && _portfolioAchievements == null) {
      _loadPortfolio();
    }
  }

  Future<void> _edit([Achievement? achievement]) async {
    final details = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AchievementFormDialog(achievement: achievement),
    );
    if (details == null || !mounted) {
      return;
    }
    setState(() => _working = true);
    try {
      await widget.api.saveAchievement(details, achievementId: achievement?.id);
      await _load();
      _portfolioAchievements = null;
      if (mounted) {
        _message(
          achievement == null ? 'Achievement added' : 'Achievement updated',
        );
      }
    } catch (error) {
      if (mounted) {
        _message(error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _delete(Achievement achievement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete achievement?'),
        content: Text('Delete "${achievement.title}" from your portfolio?'),
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
      await widget.api.deleteAchievement(achievement.id, asAdmin: false);
      await _load();
      _portfolioAchievements = null;
      if (mounted) {
        _message('Achievement deleted');
      }
    } catch (error) {
      if (mounted) {
        _message(error.toString(), isError: true);
      }
    }
  }

  Future<void> _download() async {
    setState(() => _working = true);
    try {
      await widget.api.downloadPortfolio();
      if (mounted) {
        _message('Portfolio PDF downloaded');
      }
    } catch (error) {
      if (mounted) {
        _message(error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
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
      title: 'Student workspace',
      destinations: _destinations,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _selectDestination,
      onLogout: widget.onLogout,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: _buildSelectedPage(),
    );
  }

  Widget _buildSelectedPage() {
    if (_selectedIndex == 2) {
      return _portfolioPage();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 600 ? 20.0 : 36.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 36),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _welcomeHeader(context),
                    const SizedBox(height: 22),
                    _buildStats(context, constraints.maxWidth),
                    const SizedBox(height: 28),
                    if (_selectedIndex == 0) ...[
                      _sectionHeader(
                        'Recent achievements',
                        action: TextButton.icon(
                          onPressed: () => _selectDestination(1),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: const Text('View all'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      _sectionHeader(
                        'Your achievements',
                        action: FilledButton.icon(
                          onPressed: _working ? null : () => _edit(),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add achievement'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _achievementContent(
                      context,
                      recentOnly: _selectedIndex == 0,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _welcomeHeader(BuildContext context) {
    final firstName = widget.user.fullName.trim().split(RegExp(r'\s+')).first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return Container(
          padding: EdgeInsets.all(compact ? 22 : 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CampusColors.navy, CampusColors.indigo],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1C202447),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR ACHIEVEMENT JOURNEY',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFD8D8F1),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome back, $firstName',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: compact ? 25 : 32,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every milestone deserves a place in your story.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: const Color(0xFFE0E0F0)),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: CampusColors.navy,
                          ),
                          onPressed: _working ? null : () => _edit(),
                          icon: const Icon(Icons.add_rounded, size: 19),
                          label: const Text('Add achievement'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0x80FFFFFF)),
                          ),
                          onPressed: () => _selectDestination(2),
                          icon: const Icon(
                            Icons.auto_awesome_outlined,
                            size: 18,
                          ),
                          label: const Text('View portfolio'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 24),
                Container(
                  width: 126,
                  height: 126,
                  decoration: BoxDecoration(
                    color: const Color(0x20FFFFFF),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0x40FFFFFF)),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFE3DFFB),
                    size: 62,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats(BuildContext context, double width) {
    final categories = _achievements
        .map((item) => item.category)
        .toSet()
        .length;
    final newest = _achievements.isEmpty ? null : _achievements.first.date;
    final compact = width < 700;
    final cards = [
      _StatCard(
        icon: Icons.workspace_premium_outlined,
        label: 'Achievements',
        value: _loading ? '—' : '${_achievements.length}',
        detail: 'Milestones documented',
        tint: CampusColors.lavender,
        accent: CampusColors.indigo,
      ),
      _StatCard(
        icon: Icons.category_outlined,
        label: 'Categories',
        value: _loading ? '—' : '$categories',
        detail: 'Areas of achievement',
        tint: CampusColors.mint,
        accent: CampusColors.green,
      ),
      _StatCard(
        icon: Icons.calendar_month_outlined,
        label: 'Latest milestone',
        value: newest == null ? '—' : _formatDate(newest),
        detail: newest == null ? 'Ready for your first' : 'Keep it going',
        tint: CampusColors.amber,
        accent: const Color(0xFF9A702A),
      ),
    ];

    if (compact) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.only(right: 14),
                child: card,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _achievementContent(BuildContext context, {required bool recentOnly}) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(44),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _MessagePanel(
        icon: Icons.cloud_off_outlined,
        title: 'Achievements could not be loaded',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_achievements.isEmpty) {
      return _MessagePanel(
        icon: Icons.auto_awesome_outlined,
        title: 'Your story starts here',
        message:
            'Add a competition, project, certification or campus milestone. '
            'It will be part of your portfolio right away.',
        actionLabel: 'Add your first achievement',
        onAction: _edit,
      );
    }

    final achievements = recentOnly
        ? _achievements.take(3).toList()
        : _achievements;
    return LayoutBuilder(
      builder: (context, constraints) {
        final grid = constraints.maxWidth >= 940;
        if (!grid) {
          return Column(
            children: achievements
                .map(
                  (achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AchievementCard(
                      achievement: achievement,
                      actions: _achievementActions(achievement),
                    ),
                  ),
                )
                .toList(),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: achievements.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 510,
            mainAxisExtent: 220,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) => AchievementCard(
            achievement: achievements[index],
            actions: _achievementActions(achievements[index]),
          ),
        );
      },
    );
  }

  List<Widget> _achievementActions(Achievement achievement) => [
    IconButton(
      tooltip: 'Edit achievement',
      onPressed: _working ? null : () => _edit(achievement),
      icon: const Icon(Icons.edit_outlined),
    ),
    IconButton(
      tooltip: 'Delete achievement',
      onPressed: () => _delete(achievement),
      icon: const Icon(Icons.delete_outline_rounded),
    ),
  ];

  Widget _portfolioPage() {
    final achievements = _portfolioAchievements ?? _achievements;
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = constraints.maxWidth < 600 ? 20.0 : 36.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(inset, 18, inset, 36),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      'Portfolio preview',
                      action: FilledButton.icon(
                        onPressed: _working ? null : _download,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download PDF'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PortfolioHeader(user: widget.user),
                    const SizedBox(height: 20),
                    if (_portfolioLoading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_portfolioError != null)
                      _MessagePanel(
                        icon: Icons.cloud_off_outlined,
                        title: 'Portfolio preview unavailable',
                        message: _portfolioError!,
                        actionLabel: 'Try again',
                        onAction: _loadPortfolio,
                      )
                    else if (achievements.isEmpty)
                      const _MessagePanel(
                        icon: Icons.description_outlined,
                        title: 'Your portfolio is ready to grow',
                        message: 'Achievements you add will appear here immediately.',
                      )
                    else ...[
                      Text(
                        'ACHIEVEMENT RECORD',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: CampusColors.muted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...achievements.map(
                        (achievement) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AchievementCard(achievement: achievement),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title, {Widget? action}) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} '
      '${_month(date.month)} ${date.year}';

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.tint,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 3),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 34, color: CampusColors.indigo),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel case final label?) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PortfolioHeader extends StatelessWidget {
  const _PortfolioHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: CampusColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CampusColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A202447),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                color: CampusColors.indigo,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'THIAGARAJAR COLLEGE OF ENGINEERING',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: CampusColors.indigo,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 22,
            runSpacing: 10,
            children: [
              _IdentityItem(
                label: 'ROLL NUMBER',
                value: user.rollNumber ?? '—',
              ),
              _IdentityItem(label: 'DEPARTMENT', value: user.department ?? '—'),
              _IdentityItem(
                label: 'YEAR OF STUDY',
                value: '${user.yearOfStudy ?? '—'}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentityItem extends StatelessWidget {
  const _IdentityItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 185,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: CampusColors.muted, letterSpacing: 0.75),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
