/// Model for representing an extracted event
/// Matches the backend Event schema from backend_structure.md
class EventModel {
  final String id;
  final String reportId; // Reference to original report
  final String eventType; // "flooding", "accident", "fire", etc.
  final String locationHint;
  final String timeHint;
  final int severity; // 1-5
  final String summary;
  final double confidence; // 0.0-1.0
  final Map<String, dynamic>? extractedJson; // Full JSON from Gemini
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.reportId,
    required this.eventType,
    required this.locationHint,
    required this.timeHint,
    required this.severity,
    required this.summary,
    required this.confidence,
    this.extractedJson,
    required this.createdAt,
  });

  /// Create EventModel from JSON response
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id'] ?? json['id'] ?? '',
      reportId: json['report_id'] ?? '',
      eventType: json['event_type'] ?? 'unknown',
      locationHint: json['location_hint'] ?? 'Location not specified',
      timeHint: json['time_hint'] ?? 'Time not specified',
      severity: json['severity'] ?? 3,
      confidence: (json['confidence'] ?? 0.5).toDouble(),
      summary: json['summary'] ?? '',
      extractedJson: json['extracted_json'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Convert EventModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'report_id': reportId,
      'event_type': eventType,
      'location_hint': locationHint,
      'time_hint': timeHint,
      'severity': severity,
      'summary': summary,
      'confidence': confidence,
      'extracted_json': extractedJson,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get severity color for UI display
  String getSeverityColor() {
    if (severity <= 2) return '#4CAF50'; // Green
    if (severity == 3) return '#FFC107'; // Yellow
    if (severity == 4) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  /// Get severity level description
  String getSeverityDescription() {
    if (severity <= 2) return 'Low';
    if (severity == 3) return 'Medium';
    if (severity == 4) return 'High';
    return 'Critical';
  }

  /// Get confidence percentage for display
  String getConfidencePercentage() {
    return '${(confidence * 100).toStringAsFixed(0)}%';
  }

  /// Get formatted event type (capitalize first letter)
  String getFormattedEventType() {
    if (eventType.isEmpty) return 'Unknown';
    return eventType[0].toUpperCase() + eventType.substring(1);
  }

  /// Get event type icon/emoji
  String getEventTypeIcon() {
    switch (eventType.toLowerCase()) {
      case 'flooding':
      case 'flood':
        return '🌊';
      case 'fire':
        return '🔥';
      case 'accident':
      case 'crash':
        return '🚗';
      case 'violence':
      case 'assault':
        return '⚠️';
      case 'medical':
      case 'health':
        return '🏥';
      case 'theft':
      case 'robbery':
        return '🚨';
      case 'protest':
      case 'demonstration':
        return '📢';
      case 'power outage':
      case 'blackout':
        return '💡';
      case 'earthquake':
        return '🌍';
      case 'storm':
      case 'weather':
        return '⛈️';
      default:
        return '📍';
    }
  }

  /// Get formatted time string for display
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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

  /// Check if event is recent (within last 30 minutes)
  bool isRecent() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inMinutes < 30;
  }

  /// Check if event is critical (severity >= 4)
  bool isCritical() {
    return severity >= 4;
  }

  /// Check if event has high confidence (>= 0.7)
  bool isHighConfidence() {
    return confidence >= 0.7;
  }

  /// Get confidence level description
  String getConfidenceDescription() {
    if (confidence >= 0.8) return 'High confidence';
    if (confidence >= 0.6) return 'Medium confidence';
    return 'Low confidence';
  }

  /// Copy with method for updating event
  EventModel copyWith({
    String? id,
    String? reportId,
    String? eventType,
    String? locationHint,
    String? timeHint,
    int? severity,
    String? summary,
    double? confidence,
    Map<String, dynamic>? extractedJson,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      eventType: eventType ?? this.eventType,
      locationHint: locationHint ?? this.locationHint,
      timeHint: timeHint ?? this.timeHint,
      severity: severity ?? this.severity,
      summary: summary ?? this.summary,
      confidence: confidence ?? this.confidence,
      extractedJson: extractedJson ?? this.extractedJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'EventModel(id: $id, eventType: $eventType, severity: $severity, location: $locationHint)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}