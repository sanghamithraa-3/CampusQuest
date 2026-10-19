import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../theme/campus_theme.dart';

class AchievementFormDialog extends StatefulWidget {
  const AchievementFormDialog({this.achievement, super.key});

  final Achievement? achievement;

  @override
  State<AchievementFormDialog> createState() => _AchievementFormDialogState();
}

class _AchievementFormDialogState extends State<AchievementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _certificateUrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final achievement = widget.achievement;
    _title = TextEditingController(text: achievement?.title ?? '');
    _category = TextEditingController(text: achievement?.category ?? '');
    _description = TextEditingController(text: achievement?.description ?? '');
    _certificateUrl = TextEditingController(
      text: achievement?.certificateUrl ?? '',
    );
    _date = achievement?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _description.dispose();
    _certificateUrl.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _date = date);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop({
      'title': _title.text.trim(),
      'category': _category.text.trim(),
      'date': DateTime(_date.year, _date.month, _date.day).toIso8601String(),
      'description': _description.text.trim(),
      'certificateUrl': _certificateUrl.text.trim(),
    });
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: CampusColors.lavender,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: CampusColors.indigo,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.achievement == null
                              ? 'Add an achievement'
                              : 'Edit achievement',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Add a milestone to your student portfolio.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _title,
                          decoration: const InputDecoration(
                            labelText: 'Achievement title',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                          validator: _required,
                          maxLength: 160,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'Competition, project, certification…',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          validator: _required,
                          maxLength: 80,
                        ),
                        const SizedBox(height: 8),
                        Card(
                          color: CampusColors.paper,
                          child: ListTile(
                            leading: const Icon(
                              Icons.calendar_month_outlined,
                              color: CampusColors.indigo,
                            ),
                            title: const Text('Achievement date'),
                            subtitle: Text(
                              '${_date.year.toString().padLeft(4, '0')}-'
                              '${_date.month.toString().padLeft(2, '0')}-'
                              '${_date.day.toString().padLeft(2, '0')}',
                            ),
                            trailing: const Icon(Icons.edit_calendar_outlined),
                            onTap: _chooseDate,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _description,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText:
                                'Share a little context about this milestone',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          maxLength: 3000,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _certificateUrl,
                          decoration: const InputDecoration(
                            labelText: 'Certificate URL (optional)',
                            hintText: 'https://…',
                            prefixIcon: Icon(Icons.link_rounded),
                            helperText: 'Add a link to an online certificate. No file upload.',
                          ),
                          keyboardType: TextInputType.url,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final uri = Uri.tryParse(value.trim());
                            if (uri == null ||
                                !uri.hasAuthority ||
                                !['http', 'https'].contains(uri.scheme)) {
                              return 'Enter an HTTP or HTTPS URL';
                            }
                            return null;
                          },
                          maxLength: 2048,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save achievement'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
