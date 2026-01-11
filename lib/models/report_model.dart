class ReportModel{
  final String id;
  final String rawText;
  final String evidenceType;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.rawText,
    required this.evidenceType,
    required this.createdAt,
});

  //Create Report Model from JSON Response
factory ReportModel.fromJson(Map<String, dynamic> json) {
  return ReportModel(
id: json['id'] ?? json['id'] ?? '',
      rawText: json['raw_text'] ?? '',
      evidenceType: json['evidence_type'] ?? 'text',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
  );
}

//Convert Report Model to JSON for sending to backend
Map<String, dynamic> toJson() {
  return {
    'text': rawText,
    'evidence_type': evidenceType,
  };
}
/// Convert to JSON with full fields (for storage/display)
Map<String, dynamic> toJsonFull() {
  return {
    '_id': id,
    'raw_text': rawText,
    'evidence_type': evidenceType,
    'created_at': createdAt.toIso8601String(),
  };
}

//Get formatted evidence type
String getEvidenceTypeIcon() {
  switch( evidenceType.toLowerCase()) {
    case 'text':
      return '📄';
    case 'audio':
    case 'voice':
      return '🎤';
    case 'image':
    case 'photo':
      return '📷';
    case 'video':
      return '🎥';
    default:
      return '📄';
  }
}
//Get formated evidence Type
String getFormattedEvidenceType() {
  if (evidenceType.isEmpty) return 'Unknown';
  return evidenceType[0].toUpperCase() + evidenceType.substring(1);
}

//get Formatted time string for display
String getFormattedTime() {
  final now = DateTime.now();
  final difference = now.difference(createdAt);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  else {
    return '${difference.inDays}d ago';
  }
}

//Get full formatted Date/Time
  String getFullFormattedDateTime() {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final month = months[createdAt.month - 1];
  final day = createdAt.day;
  final year = createdAt.year;
  final hour = createdAt.hour.toString().padLeft(2, '0');
  final minute = createdAt.minute.toString().padLeft(2, '0');

  return '$month $day, $year at $hour:$minute';
  }

  /// Get truncated text preview (for UI lists)
  String getTextPreview({int maxLength = 100}) {
    if (rawText.length <= maxLength) {
      return rawText;
    }
    return '${rawText.substring(0, maxLength)}...';
  }

  /// Check if report is recent (within last 5 minutes)
  bool isRecent() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inMinutes < 5;
  }

  /// Validate if report has required fields
  bool isValid() {
    return rawText.isNotEmpty && evidenceType.isNotEmpty;
  }

  /// Get word count (useful for analytics)
  int getWordCount() {
    return rawText.trim().split(RegExp(r'\s+')).length;
  }

  /// Check if report is multimodal (not just text)
  bool isMultimodal() {
    return evidenceType.toLowerCase() != 'text';
  }

  /// Copy with method for updating report
  ReportModel copyWith({
    String? id,
    String? rawText,
    String? evidenceType,
    DateTime? createdAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      evidenceType: evidenceType ?? this.evidenceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ReportModel(id: $id, evidenceType: $evidenceType, preview: ${getTextPreview(maxLength: 50)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReportModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Helper class for creating report submissions
class ReportSubmission {
  final String text;
  final String evidenceType;
  final String location;
  final int severity;

  ReportSubmission({
    required this.text,
    required this.evidenceType,
    required this.location,
    required this.severity,
  });

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'evidence_type': evidenceType,
      'location': location,
      'severity': severity,
    };
  }

  /// Validate submission
  bool isValid() {
    return text.trim().isNotEmpty &&
        evidenceType.isNotEmpty &&
        location.trim().isNotEmpty &&
        severity > 1 && severity <= 5 &&
        ['text', 'audio', 'image', 'video'].contains(evidenceType.toLowerCase());
  }

  /// Get validation error message
  String? getValidationError() {
    if (text.trim().isEmpty) {
      return 'Report text cannot be empty';
    }
    if (evidenceType.isEmpty) {
      return 'Evidence type must be specified';
    }
    if (location.trim().isEmpty) {
      return 'Location is required';
    }
    if (severity < 1 || severity > 5) {
      return 'Severity must be between 1 and 5';
    }
    if (!['text', 'audio', 'image', 'video'].contains(evidenceType.toLowerCase())) {
      return 'Invalid evidence type. Must be text, audio, image, or video';
    }
    return null;
  }
}