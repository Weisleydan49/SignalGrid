import 'package:flutter/material.dart';
import '../models/brief_model.dart';
import '../services/api_service.dart';

/// Screen for viewing the latest situation brief
/// Shows AI-generated summary of current situation
class BriefScreen extends StatefulWidget {
  const BriefScreen({super.key});

  @override
  State<BriefScreen> createState() => _BriefScreenState();
}

class _BriefScreenState extends State<BriefScreen> {
  // API service
  final ApiService _apiService = ApiService();

  // State
  BriefModel? _brief;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBrief();
  }

  /// Load latest brief from backend
  Future<void> _loadBrief() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final brief = await _apiService.getLatestBrief();
      setState(() {
        _brief = brief;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Pull to refresh
  Future<void> _handleRefresh() async {
    await _loadBrief();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Situation Brief'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Brief',
            onPressed: _loadBrief,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading && _brief == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading situation brief...'),
          ],
        ),
      );
    }

    // Error state (no brief available)
    if (_errorMessage != null && _brief == null) {
      final bool isNoBrief = _errorMessage!.contains('No briefs available');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isNoBrief ? Icons.article_outlined : Icons.error_outline,
                size: 64,
                color: isNoBrief ? Colors.grey : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                isNoBrief ? 'No Briefs Yet' : 'Error Loading Brief',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isNoBrief
                    ? 'Submit reports and run AI cycle to generate briefs'
                    : _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadBrief,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Brief display
    if (_brief != null) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timestamp
              Text(
                'Last Updated: ${_brief!.timeAgo}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Headline
              _buildHeadlineCard(),

              const SizedBox(height: 16),

              // What Changed
              if (_brief!.whatChanged.isNotEmpty) _buildWhatChangedCard(),

              const SizedBox(height: 16),

              // Top Hotspots
              if (_brief!.topHotspots.isNotEmpty) _buildHotspotsCard(),

              const SizedBox(height: 16),

              // Watch Next
              if (_brief!.watchNext.isNotEmpty) _buildWatchNextCard(),

              const SizedBox(height: 16),

              // Confidence Notes
              if (_brief!.confidenceNotes != null && 
                  _brief!.confidenceNotes!.isNotEmpty) 
                _buildConfidenceCard(),

              const SizedBox(height: 80), // Extra space at bottom
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Headline card
  Widget _buildHeadlineCard() {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.campaign,
              size: 40,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              _brief!.headline,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// What Changed card
  Widget _buildWhatChangedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.change_circle,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'What Changed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._brief!.whatChanged.map((change) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      change,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Top Hotspots card
  Widget _buildHotspotsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Top Hotspots',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._brief!.topHotspots.asMap().entries.map((entry) {
              final index = entry.key;
              final hotspot = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    // Navigate to clusters screen (index 1) if inside a TabController
                    final tabController = DefaultTabController.of(context);
                    if (tabController != null) {
                      tabController.animateTo(1);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 16,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hotspot,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Watch Next card
  Widget _buildWatchNextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.visibility,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Watch Next',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.trending_up,
                    size: 20,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _brief!.watchNext,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confidence Notes card
  Widget _buildConfidenceCard() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Confidence Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _brief!.confidenceNotes ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
