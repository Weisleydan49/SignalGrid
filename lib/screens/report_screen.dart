import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

///=========================================================================================================
/// Screen for submitting incident reports
/// Supports text, audio, image, and video evidence types
/// Returns extracted event data
///=========================================================================================================
class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Form controllers
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  int _selectedSeverity = 3; //Default to Moderate
  final ImagePicker _imagePicker = ImagePicker();
  FlutterSoundRecorder? _audioRecorder;
  String? _audioPath;
  File? _selectedImage;
  File? _selectedVideo;
  List<File> _attachedFiles = [];
  bool _isRecording = false;


  //To display attached media
  String? _mediaPreviewText;

  //Severity Levels
  final Map<int, String> _severityLevels = {
    1: 'Minimal',
    2: 'Minor',
    3: 'Moderate',
    4: 'Major',
    5: 'Critical',

  };

  // API service
  final ApiService _apiService = ApiService();

  // State
  String _selectedEvidenceType = 'text';
  bool _isSubmitting = false;
  EventModel? _extractedEvent;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAudioRecorder();
  }

  Future<void> _initAudioRecorder() async {
    _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.openRecorder();
  }

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
    _locationController.dispose();
    _audioRecorder?.closeRecorder();
    _audioRecorder = null;
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
        location: _locationController.text,
        severity: _selectedSeverity,
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
      _locationController.clear();
      _selectedEvidenceType = 'text';
      _selectedSeverity = 3;
      _extractedEvent = null;
      _errorMessage = null;
      _selectedImage = null;
      _selectedVideo = null;
      _audioPath = null;
      _attachedFiles.clear();
      _mediaPreviewText = null;
      _isRecording = false;
    });
  }

  IconData _getFileIcon(
      String fileName) {
    if (fileName.contains('.jpg') || fileName.contains('.jpeg') || fileName.contains('.png')) {
      return Icons.image;
      } else if (fileName.contains('.mp4') || fileName.contains('.mov') || fileName.contains('.avi')) {
      return Icons.videocam;
      } else if (fileName.contains('.mp3') || fileName.contains('.wav') || fileName.contains('.ogg') || fileName.contains('.flac')
    || fileName.contains('.aac') || fileName.contains('.m4a') || fileName.contains('.wma')) {
      return Icons.mic;
      }
      return Icons.insert_drive_file;
    }


//Get color for severity Level
  Color _getSeverityColor(int severity){
    switch(severity){
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
  ///===========================================================================
  ///MEDIA HANDLING METHODS / EVIDENCE TYPE HANDLERS
  ///===========================================================================

///Request camera permission
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  ///Request Microphone Permission
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  ///Request Storage Permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  ///Take photo with camera
  Future<void> _takePhoto() async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      _showPermissionDeniedDialog('Camera');
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(()
        {
          _selectedImage = File(photo.path);
          _selectedEvidenceType = 'image';
          _mediaPreviewText = 'Photo Captured';
          _attachedFiles.add(_selectedImage!);
        });
      }
    } catch (e) {
      _showErrorSnackbar('failed to take photo: $e');
    }
  }

  ///Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _showPermissionDeniedDialog('Storage');
      return;
    }
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedEvidenceType = 'image';
          _mediaPreviewText = 'Image Selected: ${image.name}';
          _attachedFiles.add(_selectedImage!);
        });
      }
    } catch (e) {
      _showErrorSnackbar('failed to pick image: $e');
    }
  }

  ///Record Video
  Future<void> _recordVideo() async{
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      _showPermissionDeniedDialog('Camera');
      return;
    }

    try {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );

    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
        _selectedEvidenceType = 'video';
        _mediaPreviewText = 'Video recorded (${video.name})';
        _attachedFiles.add(_selectedVideo!);
      });
    }
  } catch (e) {
    _showErrorSnackbar('Failed to record Video: $e');
    }
  }

  //Pick Video From Gallery
  Future <void> _pickVideoFromGallery() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _showPermissionDeniedDialog('Storage');
      return;
    }

    try{
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
          _selectedEvidenceType = 'video';
          _mediaPreviewText = 'Video Selected: ${video.name}';
          _attachedFiles.add(_selectedVideo!);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick video: $e');
    }
  }

  //Start / Stop recording
  Future <void> _toggleAudioRecording() async {
    if (_isRecording) {
      //Stop Recording
      try{
        final path = await _audioRecorder!.stopRecorder();
        setState(() {
          _isRecording = false;
          _audioPath = path;
          _selectedEvidenceType = 'audio';
          _mediaPreviewText = 'Audio Recorded';
          if (path != null) {
            _attachedFiles.add(File(path));
          }
        });
      } catch (e) {
        _showErrorSnackbar('Failed to stop recording: $e');
      }
    } else {
      //Start Recording
      final hasPermission = await _requestMicrophonePermission();
      if (!hasPermission) {
        _showPermissionDeniedDialog('Microphone');
        return;
      }
      try {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.acc';

        await _audioRecorder!.startRecorder(
          toFile: path,
          codec: Codec.aacADTS,
        );
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        _showErrorSnackbar('Failed to start recording: $e');
      }
    }
  }

  //Show Permission Denied Dialog
  void _showPermissionDeniedDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text('Please grant #permissionname permission in settings to use this feature.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings')
            ),
          ],
      ),
    );
  }

  //Show Error Snackbar
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //Remove Attached File
  void _removeAttachment(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
      if (_attachedFiles.isEmpty) {
        _selectedImage = null;
        _selectedVideo = null;
        _audioPath = null;
        _mediaPreviewText = null;
        _selectedEvidenceType = 'text';
      }
    });
  }


  //Show media options button sheet
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
              'Add Evidence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
          ),
        ),
            const SizedBox(height: 20),

            //Photo options
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.blue),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            ),
            const Divider(),

            //Video Options
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.red),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _recordVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: const Text('Choose video from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickVideoFromGallery();
              },
            ),
            const SizedBox(height: 10),
            ],
          ),
        ),
    );
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

              //Media attachment buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRecording ? _toggleAudioRecording : _toggleAudioRecording,
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: Text(_isRecording ? 'Stop Recording' : 'Record Audio'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isRecording ? Colors.red : Colors.blue,
                      side: BorderSide(
                        color: _isRecording ? Colors.red : Colors.blue,
                      ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _showMediaOptions,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach Media'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                      ),
                  ),
                ],
              ),
              // Show attached files preview
              if (_attachedFiles.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Attached Files:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_attachedFiles.length, (index) {
                        final file = _attachedFiles[index];
                        final fileName = file.path.split('/').last;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                _getFileIcon(fileName),
                                size: 20,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => _removeAttachment(index),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

// Recording indicator
              if (_isRecording)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Recording in progress...',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              //Location field
              const Text(
                'Location/Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'Enter incident location or address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  helperText: '* Required field',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required to submit report';
                  }
                  return null;
                },

              ),

              const SizedBox(height: 24),

              //Severity Selector
              const Text(
                'Severity (Initial Assessment)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: _getSeverityColor(_selectedSeverity),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_selectedSeverity - ${_severityLevels[_selectedSeverity]}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getSeverityColor(_selectedSeverity),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _selectedSeverity.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _severityLevels[_selectedSeverity],
                        activeColor: _getSeverityColor(_selectedSeverity),
                        onChanged: (value) {
                          setState(() {
                            _selectedSeverity = value.toInt();
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var entry in _severityLevels.entries)
                            Text(
                              '${entry.key}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedSeverity == entry.key
                                  ? _getSeverityColor(entry.key)
                                    : Colors.grey,
                                fontWeight: _selectedSeverity == entry.key
                                ? FontWeight.bold
                                  : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

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