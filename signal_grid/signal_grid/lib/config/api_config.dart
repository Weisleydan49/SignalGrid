//This class is used to store the api configurations
//Can be used to change the backend url easily
class ApiConfig{
  //Base url
  //Base url is where the backend url server is running
  //   - Use "http://localhost:5000" - testing on computer
  //   - Use "http://10.0.2.2:5000" - testing on Android emulator
  //   - Use "http://YOUR_COMPUTER_IP:5000" - testing on physical device (real android/ios device)
  // After deployment (when backend is live):
  //   - Replace with actual deployed URL "https://signalgrid-api.onrender.com"

  static const String baseUrl = "http://localhost:5000";

  //API Endpoints

  // Submit new incident reports (text, audio, image)
  // HTTP Method: POST
  // Sends report to backend, backend extracts event data using Gemini
  // Returns Extracted event JSON
static const String reportsEndpoint = "/api/reports";
// Manually triggers the AI cycle (clustering + brief generation)
  // HTTP Method: POST
  // Backend processes recent events, clusters them, generates brief
  // Returns Updated clusters and latest brief
static const String cycleEndpoint = "/api/cycle/run";
// Fetch all current event clusters
  // HTTP Method: GET
  // What it does: Retrieves all active clusters from database
  // Returns: Array of cluster objects
static const String clustersEndpoint = "/api/clusters";
  //Retrieves the latest generated brief from database
  // Returns: Single brief object with all sections
static const String clusterByIdEndpoint = "/api/clusters";
// What it does: Retrieves all briefs ordered by time
  // Returns: Array of brief objects
static const String latestBriefEndpoint = "/api/briefs/latest";

static const String allBriefsEndpoint = "/api/briefs";

//HELPER METHODS

static String get reportsUrl => "$baseUrl$reportsEndpoint";
static String get cycleUrl => "$baseUrl$cycleEndpoint";
static String get clustersUrl => "$baseUrl$clustersEndpoint";
  static String clusterByIdUrl(String clusterId) {
    return baseUrl + clusterByIdEndpoint + "/$clusterId";
  }
  static String get allBriefsUrl => "$baseUrl$allBriefsEndpoint";
  static String get latestBriefUrl => "$baseUrl$latestBriefEndpoint";

  static const int connectionTimeout = 30; //30 seconds
  static const int receiveTimeout = 30; //30 seconds
//Request completed
static const int statusOk = 200;
//Resource created
static const int statusCreated = 201;
//invalid Data
static const int statusBadRequest = 400;
//Unauthorized
//static const int statusUnauthorized = 401;
//Not found
static const int statusNotFound = 404;
//Internal Server Error
static const int statusInternalServerError = 500;

static const String evidenceTypeText = "text";
static const String evidenceTypeAudio = "audio";
static const String evidenceTypeImage = "image";
static const String evidenceTypeVideo = "video";

}




