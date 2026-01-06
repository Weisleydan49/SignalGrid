import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';

/// Screen for submitting incident reports
/// Supports text, audio, image, and video evidence types
class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Form controllers
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // API service
  final ApiService _apiService = ApiService();

  // State
  String _selectedEvidenceType = 'text';
  bool _isSubmitting = false;
  EventModel? _extractedEvent;
  String? _errorMessage;

  // Evidence type options
  final List<Map<String, dynamic>> _evidenceTypes = [
    {'value': 'text', 'label': 'Text', 'icon': Icons.text_fields},
    {'value': 'audio', 'label': 'Audio', 'icon': Icons.mic},
    {'value': 'image', 'label': 'Image', 'icon': Icons.image},
    {'value': 'video', 'label': 'Video', 'icon': Icons.videocam},
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Submit report to backend
  Future<void> _submitReport() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear previous results
    setState(() {
      _isSubmitting = true;
      _extractedEvent = null;
      _errorMessage = null;
    });

    try {
      // Submit report
      final event = await _apiService.submitReport(
        _textController.text,
        _selectedEvidenceType,
      );

      // Show success
      setState(() {
        _extractedEvent = event;
        _isSubmitting = false;
      });

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Clear form and results
  void _clearForm() {
    setState(() {
      _textController.clear();
      _selectedEvidenceType = 'text';
      _extractedEvent = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Incident Report'),
        actions: [
          if (_extractedEvent != null || _errorMessage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'New Report',
              onPressed: _clearForm,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Describe the incident you witnessed. Include location, time, and details.',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Evidence type selector
              const Text(
                'Evidence Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _evidenceTypes.map((type) {
                  final isSelected = _selectedEvidenceType == type['value'];
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(type['label']),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedEvidenceType = type['value'];
                        });
                      }
                    },
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Text input
              const Text(
                'Incident Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _textController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Example: Heavy flooding on Main Street near the market. Water is knee-deep and rising. Several cars are stuck.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter incident description';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more details (at least 10 characters)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Submit Report',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 24),

              // Extracted event display
              if (_extractedEvent != null) _buildEventResult(),

              // Error display
              if (_errorMessage != null) _buildErrorResult(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build extracted event result card
  Widget _buildEventResult() {
    final event = _extractedEvent!;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Event Extracted',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Event type with icon
            Row(
              children: [
                Text(
                  event.getEventTypeIcon(),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Event Type',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        event.getFormattedEventType(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Summary
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event.summary,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),

            // Details grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Severity',
                    event.getSeverityDescription(),
                    Color(int.parse(
                      event.getSeverityColor().substring(1),
                      radix: 16,
                    ) + 0xFF000000),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailItem(
                    'Confidence',
                    event.getConfidencePercentage(),
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Location
            _buildDetailRow(Icons.location_on, 'Location', event.locationHint),

            const SizedBox(height: 8),

            // Time
            _buildDetailRow(Icons.access_time, 'Time', event.timeHint),

            const Divider(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Submit Another'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to clusters screen
                      DefaultTabController.of(context)?.animateTo(1);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('View Clusters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  /// Build error result card
  Widget _buildErrorResult() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Submission Failed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submitReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}