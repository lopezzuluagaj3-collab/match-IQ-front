class ActivityItem {
  ActivityItem({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });
  final String title;
  final String description;
  final String timestamp;
  final ActivityType type;
}

enum ActivityType { match, interview, view, test }
