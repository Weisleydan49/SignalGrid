class ClusterModel{
  final String id;
  final String clusterId;
  final String label;
  final String summary;
  final int severity;
  final double confidence;
  final String trend;
  final List<String> relatedEventIds;
  final Map<String, dynamic>? clusterJson;
  final DateTime updatedAt;

  ClusterModel({
    required this.id,
    required this.clusterId,
    required this.label,
    required this.summary,
    required this.severity,
    required this.confidence,
    required this.trend,
    required this.relatedEventIds,
    this.clusterJson,
    required this.updatedAt,
  });

  factory ClusterModel.fromJson(Map<String, dynamic> json) {
    return ClusterModel(
      id: json['id'] ?? json['id'] ?? '',
      clusterId: json['cluster_id'] ?? '',
      label: json['label'] ?? 'Unknown Event',
      summary: json['summary'] ?? '',
      severity: json['severity'] ?? 3,
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      trend: json['trend'] ?? 'stable',
      relatedEventIds: List<String>.from(json['related_event_ids'] ?? []),
      clusterJson: json['cluster_json'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
  /// Convert ClusterModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cluster_id': clusterId,
      'label': label,
      'summary': summary,
      'severity': severity,
      'confidence': confidence,
      'trend': trend,
      'related_event_ids': relatedEventIds,
      'cluster_json': clusterJson,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get severity color for UI display
  /// Green (1-2), Yellow (3), Orange (4), Red (5)
  String getSeverityColor() {
    if (severity <= 2) return '#4CAF50'; // Green
    if (severity == 3) return '#FFC107'; // Yellow
    if (severity == 4) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  /// Get trend emoji for UI display
  String getTrendEmoji() {
    switch (trend.toLowerCase()) {
      case 'escalating':
        return '↗️';
      case 'stable':
        return '→';
      case 'resolving':
        return '↘️';
      case 'emerging':
        return '🆕';
      default:
        return '→';
    }
  }

  /// Get human-readable trend description
  String getTrendDescription() {
    switch (trend.toLowerCase()) {
      case 'escalating':
        return 'Situation is worsening';
      case 'stable':
        return 'Situation is stable';
      case 'resolving':
        return 'Situation is improving';
      case 'emerging':
        return 'New situation developing';
      default:
        return 'Status unknown';
    }
  }

  /// Get confidence percentage for display
  String getConfidencePercentage() {
    return '${(confidence * 100).toStringAsFixed(0)}%';
  }

  /// Get severity level description
  String getSeverityDescription() {
    if (severity <= 2) return 'Low';
    if (severity == 3) return 'Medium';
    if (severity == 4) return 'High';
    return 'Critical';
  }

  /// Check if cluster is recent (within last hour)
  bool isRecent() {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    return difference.inHours < 1;
  }

  /// Check if cluster is critical (severity >= 4)
  bool isCritical() {
    return severity >= 4;
  }

  /// Get formatted time string for display
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Copy with method for updating cluster
  ClusterModel copyWith({
    String? id,
    String? clusterId,
    String? label,
    String? summary,
    int? severity,
    double? confidence,
    String? trend,
    List<String>? relatedEventIds,
    Map<String, dynamic>? clusterJson,
    DateTime? updatedAt,
  }) {
    return ClusterModel(
      id: id ?? this.id,
      clusterId: clusterId ?? this.clusterId,
      label: label ?? this.label,
      summary: summary ?? this.summary,
      severity: severity ?? this.severity,
      confidence: confidence ?? this.confidence,
      trend: trend ?? this.trend,
      relatedEventIds: relatedEventIds ?? this.relatedEventIds,
      clusterJson: clusterJson ?? this.clusterJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ClusterModel(id: $id, clusterId: $clusterId, label: $label, severity: $severity, trend: $trend)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ClusterModel &&
        other.id == id &&
        other.clusterId == clusterId;
  }

  @override
  int get hashCode => id.hashCode ^ clusterId.hashCode;
}