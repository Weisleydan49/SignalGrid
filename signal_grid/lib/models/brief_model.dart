class BriefModel {
  final String? id;
  final String headline;
  final List<String> whatChanged;
  final List<String> topHotspots;
  final String watchNext;
  final String? confidenceNotes;
  final DateTime createdAt;
  final Map<String, dynamic>? fullJson;

  BriefModel({
    this.id,
    required this.headline,
    required this.whatChanged,
    required this.topHotspots,
    required this.watchNext,
    this.confidenceNotes,
    required this.createdAt,
    this.fullJson,
  });

  factory BriefModel.fromJson(Map<String, dynamic> json) {
    final briefData = json['brief_json'] ?? json;

    return BriefModel(
      id: json['_id'],
      headline: briefData['headline'] ?? '',
      whatChanged: (briefData['what_changed'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      topHotspots: (briefData['top_hotspots'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      watchNext: briefData['watch_next'] ?? '',
      confidenceNotes: briefData['confidence_notes'],
      createdAt: briefData['created_at'] != null
          ? DateTime.parse(briefData['created_at'])
          : DateTime.now(),
      fullJson: briefData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'brief_json': {
        'headline': headline,
        'what_changed': whatChanged,
        'top_hotspots': topHotspots,
        'watch_next': watchNext,
        if (confidenceNotes != null) 'confidence_notes': confidenceNotes,
        'created_at': createdAt.toIso8601String(),
      },
    };
  }

  /// Checks if this brief has any actual content
  /// Returns false if brief is essentially empty
  /// Useful for UI logic (e.g., show placeholder if empty)
  bool get hasContent {
    return headline.isNotEmpty ||
        whatChanged.isNotEmpty ||
        topHotspots.isNotEmpty;
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      final days = diff.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
  }

  int get totalItems {
    return whatChanged.length +
        topHotspots.length +
        (watchNext.isNotEmpty ? 1 : 0);
  }

  bool get hasCriticalHotspots {
    return topHotspots.isNotEmpty;
  }

  String get quickSummary {
    final hotspotCount = topHotspots.length;
    final updateCount = whatChanged.length;

    if (hotspotCount == 0 && updateCount == 0) {
      return "No Active Incidents";
    }

    final parts = <String>[];
    if (hotspotCount > 0) {
      parts.add('$hotspotCount ${hotspotCount == 1 ? 'Hotspot' : 'Hotspots'}');
    }
    if (updateCount > 0) {
      parts.add('$updateCount ${updateCount == 1 ? 'Update' : 'Updates'}');
    }
    return parts.join(', ');
  }

  BriefModel copyWith({
    String? id,
    String? headline,
    List<String>? whatChanged,
    List<String>? topHotspots,
    String? watchNext,
    String? confidenceNotes,
    DateTime? createdAt,
    Map<String, dynamic>? fullJson,
  }) {
    return BriefModel(
      id: id ?? this.id,
      headline: headline ?? this.headline,
      whatChanged: whatChanged ?? this.whatChanged,
      topHotspots: topHotspots ?? this.topHotspots,
      watchNext: watchNext ?? this.watchNext,
      confidenceNotes: confidenceNotes ?? this.confidenceNotes,
      createdAt: createdAt ?? this.createdAt,
      fullJson: fullJson ?? this.fullJson,
    );
  }

  @override
  String toString() {
    return 'BriefModel(id: $id, headline: $headline, '
        'hotspots: ${topHotspots.length}, updates: ${whatChanged.length}, '
        'createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BriefModel &&
        other.id == id &&
        other.headline == headline &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ headline.hashCode ^ createdAt.hashCode;
  }
}
