class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.description,
    required this.certificateUrl,
    this.studentId,
    this.studentName,
  });

  final String id;
  final String title;
  final String category;
  final DateTime date;
  final String description;
  final String certificateUrl;
  final String? studentId;
  final String? studentName;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    return Achievement(
      id: (json['id'] ?? json['_id']).toString(),
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      date: DateTime.parse(json['date'] as String).toLocal(),
      description: json['description'] as String? ?? '',
      certificateUrl: json['certificateUrl'] as String? ?? '',
      studentId: student is Map<String, dynamic>
          ? (student['id'] ?? student['_id']).toString()
          : student?.toString(),
      studentName: student is Map<String, dynamic>
          ? student['fullName'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'date': date.toIso8601String(),
    'description': description,
    'certificateUrl': certificateUrl,
  };
}
