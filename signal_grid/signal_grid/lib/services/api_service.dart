import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report_model.dart';
import '../models/event_model.dart';
import '../models/cluster_model.dart';
import '../models/brief_model.dart';
import '../config/api_config.dart';

/// Service class for handling all API calls to the SignalGrid backend
class ApiService {
  final String baseUrl = ApiConfig.baseUrl;

  // HTTP client with default timeout
  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 30);

  /// Headers for all requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============================================================================
  // REPORT ENDPOINTS
  // ============================================================================

  /// Submit an incident report and get extracted event
  /// POST /api/reports
  ///
  /// Returns: EventModel with extracted event data
  /// Throws: Exception on error
  Future<EventModel> submitReport(String text, String evidenceType) async {
    try {
      // Validate input
      final submission = ReportSubmission(
        text: text,
        evidenceType: evidenceType,
      );

      final validationError = submission.getValidationError();
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Make API call
      final uri = Uri.parse(ApiConfig.reportsUrl);
      final response = await _client
          .post(
        uri,
        headers: _headers,
        body: jsonEncode(submission.toJson()),
      )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == ApiConfig.statusOk || 
          response.statusCode == ApiConfig.statusCreated) {
        final data = jsonDecode(response.body);
        return EventModel.fromJson(data);
      } else {
        final error = _parseError(response);
        throw Exception('Failed to submit report: $error');
      }
    } catch (e) {
      throw Exception('Error submitting report: ${e.toString()}');
    }
  }

  // ============================================================================
  // AI CYCLE ENDPOINTS
  // ============================================================================

  /// Trigger AI cycle (clustering + brief generation)
  /// POST /api/cycle/run
  ///
  /// Returns: Map with clusters and brief data
  /// Throws: Exception on error
  Future<Map<String, dynamic>> runCycle() async {
    try {
      final uri = Uri.parse(ApiConfig.cycleUrl);
      final response = await _client
          .post(
        uri,
        headers: _headers,
      )
          .timeout(_timeout);

      if (response.statusCode == ApiConfig.statusOk || 
          response.statusCode == ApiConfig.statusCreated) {
        final data = jsonDecode(response.body);
        
        final clusters = (data['clusters'] as List?)
            ?.map((c) => ClusterModel.fromJson(c))
            .toList() ?? [];
            
        final briefJson = data['brief'] ?? data['latest_brief'];
        final brief = briefJson != null ? BriefModel.fromJson(briefJson) : null;

        return {
          'clusters': clusters,
          'brief': brief,
        };
      } else {
        final error = _parseError(response);
        throw Exception('Failed to run cycle: $error');
      }
    } catch (e) {
      throw Exception('Error running AI cycle: ${e.toString()}');
    }
  }

  // ============================================================================
  // CLUSTER ENDPOINTS
  // ============================================================================

  /// Get all active clusters
  /// GET /api/clusters
  ///
  /// Returns: List of ClusterModel objects
  /// Throws: Exception on error
  Future<List<ClusterModel>> getClusters() async {
    try {
      final uri = Uri.parse(ApiConfig.clustersUrl);
      final response = await _client
          .get(
        uri,
        headers: _headers,
      )
          .timeout(_timeout);

      if (response.statusCode == ApiConfig.statusOk) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ClusterModel.fromJson(json)).toList();
      } else {
        final error = _parseError(response);
        throw Exception('Failed to get clusters: $error');
      }
    } catch (e) {
      throw Exception('Error fetching clusters: ${e.toString()}');
    }
  }

  /// Get specific cluster by ID
  /// GET /api/clusters/:id
  ///
  /// Returns: ClusterModel object
  /// Throws: Exception on error
  Future<ClusterModel> getClusterById(String id) async {
    try {
      final uri = Uri.parse(ApiConfig.clusterByIdUrl(id));
      final response = await _client
          .get(
        uri,
        headers: _headers,
      )
          .timeout(_timeout);

      if (response.statusCode == ApiConfig.statusOk) {
        final data = jsonDecode(response.body);
        return ClusterModel.fromJson(data);
      } else if (response.statusCode == ApiConfig.statusNotFound) {
        throw Exception('Cluster not found');
      } else {
        final error = _parseError(response);
        throw Exception('Failed to get cluster: $error');
      }
    } catch (e) {
      throw Exception('Error fetching cluster: ${e.toString()}');
    }
  }

  // ============================================================================
  // BRIEF ENDPOINTS
  // ============================================================================

  /// Get latest situation brief
  /// GET /api/briefs/latest
  ///
  /// Returns: BriefModel object
  /// Throws: Exception on error
  Future<BriefModel> getLatestBrief() async {
    try {
      final uri = Uri.parse(ApiConfig.latestBriefUrl);
      final response = await _client
          .get(
        uri,
        headers: _headers,
      )
          .timeout(_timeout);

      if (response.statusCode == ApiConfig.statusOk) {
        final data = jsonDecode(response.body);
        return BriefModel.fromJson(data);
      } else if (response.statusCode == ApiConfig.statusNotFound) {
        throw Exception('No briefs available yet');
      } else {
        final error = _parseError(response);
        throw Exception('Failed to get brief: $error');
      }
    } catch (e) {
      throw Exception('Error fetching brief: ${e.toString()}');
    }
  }

  /// Get all briefs (history)
  /// GET /api/briefs
  ///
  /// Returns: List of BriefModel objects
  /// Throws: Exception on error
  Future<List<BriefModel>> getAllBriefs() async {
    try {
      final uri = Uri.parse(ApiConfig.allBriefsUrl);
      final response = await _client
          .get(
        uri,
        headers: _headers,
      )
          .timeout(_timeout);

      if (response.statusCode == ApiConfig.statusOk) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BriefModel.fromJson(json)).toList();
      } else {
        final error = _parseError(response);
        throw Exception('Failed to get briefs: $error');
      }
    } catch (e) {
      throw Exception('Error fetching briefs: ${e.toString()}');
    }
  }

  // ============================================================================
  // HEALTH CHECK
  // ============================================================================

  /// Check if backend API is healthy
  /// GET /health
  ///
  /// Returns: true if healthy, false otherwise
  Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == ApiConfig.statusOk;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Parse error from response
  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['error'] ?? data['message'] ?? 'Unknown error';
    } catch (e) {
      return 'Status ${response.statusCode}: ${response.reasonPhrase}';
    }
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}
