import 'package:flutter/material.dart';
import '../models/cluster_model.dart';
import '../services/api_service.dart';
import '../widgets/cluster_card.dart';

/// Screen to view all event clusters
/// Toggle between Map View and List View
class MapListScreen extends StatefulWidget {
  const MapListScreen({Key? key}) : super(key: key);

  @override
  State<MapListScreen> createState() => _MapListScreenState();
}

class _MapListScreenState extends State<MapListScreen> {
  // View mode toggle
  bool _isMapView = false; // Start with List View

  // Data
  List<ClusterModel> _clusters = [];
  bool _isLoading = false;
  String? _errorMessage;

  // API service
  final ApiService _apiService = ApiService();

  Color _getStatusColor(int severity) {
    if (severity <= 2) return Colors.green;
    if (severity == 3) return Colors.yellow;
    if (severity == 4) return Colors.orange;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    _loadClusters();
  }

  /// Load clusters from backend
  Future<void> _loadClusters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clusters = await _apiService.getClusters();
      setState(() {
        _clusters = clusters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load clusters: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Trigger AI cycle
  Future<void> _runCycle() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Running AI cycle...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await _apiService.runCycle();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Reload clusters
      await _loadClusters();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI cycle completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cycle failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pull to refresh
  Future<void> _handleRefresh() async {
    await _loadClusters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Clusters'),
        actions: [
          // View toggle button
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            tooltip: _isMapView ? 'Switch to List View' : 'Switch to Map View',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadClusters,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runCycle,
        icon: const Icon(Icons.psychology),
        label: const Text('Run AI Cycle'),
        tooltip: 'Trigger clustering and brief generation',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _clusters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading clusters...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _clusters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadClusters,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_clusters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No clusters yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Submit reports to create clusters',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _runCycle,
              icon: const Icon(Icons.psychology),
              label: const Text('Run AI Cycle'),
            ),
          ],
        ),
      );
    }

    return _isMapView ? _buildMapView() : _buildListView();
  }

  /// List View
  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_clusters.length} Active Clusters',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_clusters.where((c) => c.isCritical()).length} Critical',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Clusters list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Space for FAB
              itemCount: _clusters.length,
              itemBuilder: (context, index) {
                final cluster = _clusters[index];
                return ClusterCard(
                  title: cluster.label,
                  description: cluster.summary,
                  status: cluster.getSeverityDescription(),
                  icon: Icons.warning_amber_rounded,
                  statusColor: _getStatusColor(cluster.severity),
                  onTap: () => _showClusterDetails(cluster),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Map View (placeholder - implement with google_maps_flutter or flutter_map)
  Widget _buildMapView() {
    return Stack(
      children: [
        // Placeholder for map
        Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Map View',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Integrate Google Maps or Flutter Map here',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isMapView = false;
                    });
                  },
                  child: const Text('Switch to List View'),
                ),
              ],
            ),
          ),
        ),

        // Cluster markers overlay (when map is implemented)
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${_clusters.length} clusters on map',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show cluster details in bottom sheet
  void _showClusterDetails(ClusterModel cluster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Cluster ID and trend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cluster.clusterId,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              cluster.getTrendEmoji(),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cluster.trend,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Label
                  Text(
                    cluster.label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Severity and confidence
                  Row(
                    children: [
                      _buildBadge(
                        'Severity: ${cluster.getSeverityDescription()}',
                        Color(int.parse(
                          cluster.getSeverityColor().substring(1),
                          radix: 16,
                        ) + 0xFF000000),
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        'Confidence: ${cluster.getConfidencePercentage()}',
                        Colors.blue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Summary
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cluster.summary,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  // Related events
                  const Text(
                    'Related Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${cluster.relatedEventIds.length} reports',
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 16),

                  // Last updated
                  Text(
                    'Last updated: ${cluster.getFormattedTime()}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}