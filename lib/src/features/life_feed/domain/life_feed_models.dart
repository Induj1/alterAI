class LifeFeedTask {
  const LifeFeedTask({
    required this.title,
    required this.meta,
    required this.badge,
    this.done = false,
    this.hot = false,
  });

  factory LifeFeedTask.fromJson(Map<String, dynamic> json) {
    return LifeFeedTask(
      title: json['title'] as String? ?? '',
      meta: json['meta'] as String? ?? '',
      badge: json['badge'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      hot: json['hot'] as bool? ?? false,
    );
  }

  final String title;
  final String meta;
  final String badge;
  final bool done;
  final bool hot;
}

class LifeFeedOpportunity {
  const LifeFeedOpportunity({
    required this.tag,
    required this.matchScore,
    required this.title,
    required this.meta,
  });

  factory LifeFeedOpportunity.fromJson(Map<String, dynamic> json) {
    return LifeFeedOpportunity(
      tag: json['tag'] as String? ?? '',
      matchScore: json['match_score'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      meta: json['meta'] as String? ?? '',
    );
  }

  final String tag;
  final int matchScore;
  final String title;
  final String meta;
}

class LifeFeedSnapshot {
  const LifeFeedSnapshot({
    required this.greeting,
    required this.dateSummary,
    required this.focusTitle,
    required this.focusRationale,
    required this.tasks,
    required this.opportunities,
    required this.itemsNeedingAttention,
  });

  factory LifeFeedSnapshot.fromJson(Map<String, dynamic> json) {
    return LifeFeedSnapshot(
      greeting: json['greeting'] as String? ?? '',
      dateSummary: json['date_summary'] as String? ?? '',
      focusTitle: json['focus_title'] as String? ?? '',
      focusRationale: json['focus_rationale'] as String? ?? '',
      tasks: (json['tasks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LifeFeedTask.fromJson)
          .toList(growable: false),
      opportunities: (json['opportunities'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LifeFeedOpportunity.fromJson)
          .toList(growable: false),
      itemsNeedingAttention: json['items_needing_attention'] as int? ?? 0,
    );
  }

  static LifeFeedSnapshot empty({String firstName = 'there'}) {
    final cleanName = firstName.trim();
    return LifeFeedSnapshot(
      greeting: cleanName.isEmpty
          ? 'ALTER is ready.'
          : 'ALTER is ready, $cleanName.',
      dateSummary: 'No live feed items available yet.',
      focusTitle: '',
      focusRationale: '',
      tasks: const <LifeFeedTask>[],
      opportunities: const <LifeFeedOpportunity>[],
      itemsNeedingAttention: 0,
    );
  }

  static LifeFeedSnapshot fallback({String firstName = 'there'}) {
    return empty(firstName: firstName);
  }

  final String greeting;
  final String dateSummary;
  final String focusTitle;
  final String focusRationale;
  final List<LifeFeedTask> tasks;
  final List<LifeFeedOpportunity> opportunities;
  final int itemsNeedingAttention;
}
