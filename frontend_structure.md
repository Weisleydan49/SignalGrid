# SignalGrid Frontend Structure (Flutter)

## **Project Folder Structure**

```
signalgrid_mobile/
├── lib/
│   ├── main.dart                // App entry point
│   │
│   ├── config/
│   │   └── api_config.dart      // API base URL and constants
│   │
│   ├── models/
│   │   ├── report_model.dart    // Report data model
│   │   ├── event_model.dart     // Event data model
│   │   ├── cluster_model.dart   // Cluster data model
│   │   └── brief_model.dart     // Brief data model
│   │
│   ├── services/
│   │   ├── api_service.dart     // HTTP client and API calls
│   │   └── auth_service.dart    // Token management (optional)
│   │
│   ├── screens/
│   │   ├── splash_screen.dart   // Initial loading screen
│   │   ├── report_screen.dart   // Submit incident reports
│   │   ├── map_list_screen.dart // View clusters (map or list view)
│   │   └── brief_screen.dart    // View situation briefs
│   │
│   └── widgets/
│       ├── custom_button.dart   // Reusable button widget
│       ├── cluster_card.dart    // Cluster display card
│       └── brief_card.dart      // Brief display card
│
├── assets/
│   └── images/
│
├── test/
│
├── pubspec.yaml                 // Flutter dependencies
└── README.md
```

---

## **File Descriptions**

### **main.dart**
- App entry point
- Sets up MaterialApp
- Defines initial route (SplashScreen)
- Sets up theme

### **config/**

#### **api_config.dart**
- Stores API base URL
- Stores API endpoints as constants
- Configuration for different environments (dev/prod)

Example structure:
```dart
class ApiConfig {
  static const String baseUrl = "https://signalgrid-api.onrender.com";
  
  // Endpoints
  static const String reportsEndpoint = "/api/reports";
  static const String cycleEndpoint = "/api/cycle/run";
  static const String clustersEndpoint = "/api/clusters";
  static const String briefsEndpoint = "/api/briefs/latest";
}
```

### **models/**

Data classes that match backend JSON responses:

#### **report_model.dart**
- Represents a submitted report
- Fields: `id`, `raw_text`, `evidence_type`, `created_at`
- Methods: `fromJson()`, `toJson()`

#### **event_model.dart**
- Represents an extracted event
- Fields: `id`, `event_type`, `location_hint`, `time_hint`, `severity`, `summary`, `confidence`
- Methods: `fromJson()`, `toJson()`

#### **cluster_model.dart**
- Represents an event cluster
- Fields: `cluster_id`, `label`, `summary`, `severity`, `confidence`, `trend`, `related_event_ids`
- Methods: `fromJson()`, `toJson()`

#### **brief_model.dart**
- Represents a situation brief
- Fields: `headline`, `what_changed`, `top_hotspots`, `watch_next`, `confidence_notes`, `created_at`
- Methods: `fromJson()`, `toJson()`

### **services/**

#### **api_service.dart**
- HTTP client wrapper (using `http` or `dio` package)
- Methods:
  - `submitReport(String text, String evidenceType)` → returns Event
  - `runCycle()` → returns Clusters and Brief
  - `getClusters()` → returns List of Clusters
  - `getLatestBrief()` → returns Brief
- Handles error responses
- Handles timeouts

#### **auth_service.dart** (optional)
- Manages JWT tokens
- Methods:
  - `login(email, password)`
  - `register(email, password)`
  - `saveToken(token)`
  - `getToken()`
  - `logout()`

### **screens/**

#### **splash_screen.dart**
- Initial loading screen
- App logo/branding
- Auto-navigates to Report Screen after 2-3 seconds
- Can check authentication status here (optional)

#### **report_screen.dart**
**Purpose**: Submit incident reports

**UI Components**:
- Text input field for report text
- Evidence type selector (text/audio/image)
- Submit button
- Loading indicator
- Response panel showing extracted event summary

**Flow**:
1. User enters incident description
2. User selects evidence type
3. User taps Submit
4. Show loading indicator
5. Call `api_service.submitReport()`
6. Display extracted event JSON in formatted way
7. Option to trigger cycle or navigate to clusters

#### **map_list_screen.dart**
**Purpose**: View all event clusters

**UI Components**:
- Toggle between Map View and List View
- **Map View**: 
  - Google Maps or Flutter Map
  - Markers for each cluster (color-coded by severity)
  - Tap marker to see cluster details
- **List View**:
  - Scrollable list of ClusterCard widgets
  - Each card shows: label, severity, trend, summary
- Pull-to-refresh to reload clusters
- Floating action button to trigger cycle

**Flow**:
1. On load, call `api_service.getClusters()`
2. Display clusters
3. User can tap cluster for details
4. User can pull to refresh
5. User can trigger cycle run

#### **brief_screen.dart**
**Purpose**: View latest situation brief

**UI Components**:
- Headline (large, bold text)
- "What Changed" section (bullet points)
- Top Hotspots list (clickable to see cluster details)
- "Watch Next" section (predictions)
- Confidence Notes section
- Timestamp of brief
- Refresh button

**Flow**:
1. On load, call `api_service.getLatestBrief()`
2. Display brief in formatted layout
3. User can refresh to get updated brief
4. User can tap hotspots to navigate to map

### **widgets/**

#### **custom_button.dart**
- Reusable styled button
- Props: `text`, `onPressed`, `loading`, `color`

#### **cluster_card.dart**
- Card widget for displaying a cluster
- Shows: label, severity badge, trend indicator, summary
- Props: `cluster` (ClusterModel object)
- OnTap: navigate to details or show bottom sheet

#### **brief_card.dart**
- Card widget for displaying brief sections
- Props: `title`, `content`
- Used in brief_screen.dart

---

## **Navigation Flow**

```
SplashScreen
    ↓
ReportScreen (Home)
    ↓ (after submit)
    ├→ MapListScreen (view clusters)
    └→ BriefScreen (view brief)
```

**Bottom Navigation (Optional)**:
- Report (Home)
- Clusters (Map/List)
- Brief

---

## **Dependencies (pubspec.yaml)**

```yaml
name: signalgrid_mobile
description: SignalGrid incident reporting and situation awareness app

dependencies:
  flutter:
    sdk: flutter
  
  # HTTP client
  http: ^1.1.0
  # OR
  # dio: ^5.3.0
  
  # State management (choose one)
  provider: ^6.1.0
  # OR
  # riverpod: ^2.4.0
  
  # Maps (choose one)
  google_maps_flutter: ^2.5.0
  # OR
  # flutter_map: ^6.0.0
  
  # JSON serialization (optional)
  json_annotation: ^4.8.1
  
  # Local storage (optional for auth)
  shared_preferences: ^2.2.0
  
  # Image picker (for image reports)
  image_picker: ^1.0.4
  
  # Audio recorder (for audio reports)
  flutter_sound: ^9.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # JSON serialization (optional)
  json_serializable: ^6.7.1
  build_runner: ^2.4.6
```

---

## **API Integration Example**

### **api_service.dart structure**

```dart
class ApiService {
  final String baseUrl = ApiConfig.baseUrl;
  
  // Submit report and get extracted event
  Future<Event> submitReport(String text, String evidenceType) async {
    // POST request to /api/reports
    // Parse response to Event model
    // Handle errors
  }
  
  // Trigger AI cycle
  Future<Map<String, dynamic>> runCycle() async {
    // POST request to /api/cycle/run
    // Returns { "clusters": [...], "brief": {...} }
    // Handle errors
  }
  
  // Get all clusters
  Future<List<Cluster>> getClusters() async {
    // GET request to /api/clusters
    // Parse response to List<Cluster>
    // Handle errors
  }
  
  // Get latest brief
  Future<Brief> getLatestBrief() async {
    // GET request to /api/briefs/latest
    // Parse response to Brief model
    // Handle errors
  }
}
```

---

## **State Management Options**

### **Option 1: Provider (Recommended for MVP)**
- Simple to learn
- Good for small to medium apps
- Well documented

### **Option 2: Riverpod**
- More powerful than Provider
- Better testing support
- Steeper learning curve

### **Option 3: BLoC**
- More complex
- Better for large apps
- Overkill for MVP

**Recommendation**: Use **Provider** for MVP, can migrate later if needed.

---

## **UI/UX Considerations**

### **Report Screen**
- Keep form simple and clean
- Clear feedback on submission
- Show extracted event in readable format
- Option to submit another report quickly

### **Map/List Screen**
- Color code severity:
  - Green: Severity 1-2
  - Yellow: Severity 3
  - Orange: Severity 4
  - Red: Severity 5
- Show trend indicators:
  - ↗️ Escalating
  - → Stable
  - ↘️ Resolving
  - 🆕 Emerging

### **Brief Screen**
- Highlight what changed (bold or colored)
- Make hotspots clickable
- Show timestamp clearly
- Easy to refresh

---

## **Multimodal Input (Phase 2)**

### **Voice/Audio Reports**
- Add audio recording button to ReportScreen
- Use `flutter_sound` package
- Record audio file
- Upload to backend
- Backend transcribes or sends to Gemini
- Rest of flow same as text

### **Image Reports**
- Add camera/gallery button to ReportScreen
- Use `image_picker` package
- Capture or select image
- Upload to backend
- Backend sends to Gemini for context extraction
- Rest of flow same as text

### **Video Reports** (optional)
- Similar to image but with video
- Keep videos short (under 30 seconds for MVP)

---

## **Error Handling**

### **Network Errors**
- Show user-friendly error messages
- Retry button for failed requests
- Offline mode message

### **Validation Errors**
- Validate report text is not empty
- Show inline validation messages

### **API Errors**
- Handle 400, 404, 500 errors gracefully
- Log errors for debugging
- Show generic error message to user

---

## **Testing Strategy**

### **Widget Tests**
- Test individual widgets render correctly
- Test button interactions

### **Integration Tests**
- Test full user flows:
  1. Submit report → See event
  2. View clusters
  3. View brief

### **Manual Testing**
- Test on physical device
- Test with real backend
- Test edge cases (no internet, slow connection)

---

## **Demo Preparation**

### **For Hackathon Demo**
1. **Prepare sample reports** (5-10 ready to copy-paste)
2. **Rehearse flow**:
   - Submit 2-3 reports quickly
   - Show extracted events
   - Trigger cycle
   - Show clusters forming
   - Show brief updating
3. **Screenshots/Screen recording** for backup
4. **Offline demo mode** (optional): Load pre-fetched data if network fails

---

## **Deployment**

### **For Testing (during development)**
- Install on physical Android/iOS device via USB
- Use `flutter run` command
- Share APK with team for Android testing

### **For Demo Day**
- Build release APK: `flutter build apk --release`
- Install on demo device
- Or demo from IDE if stable

### **For Production (post-hackathon)**
- Google Play Store (Android)
- Apple App Store (iOS)
- Requires developer accounts and app review

---

## **Collaboration with Backend Team**

### **What Frontend Needs from Backend**
1. **Public API base URL**
   - Example: `https://signalgrid-api.onrender.com`

2. **API Documentation**
   - Endpoint paths
   - Request body format
   - Response format
   - Error codes

3. **Example Responses**
   - Sample JSON for each endpoint
   - Helps build models correctly

4. **Testing Credentials** (if auth implemented)
   - Test user accounts
   - Sample tokens

### **Communication Protocol**
1. Backend team posts API URL in team chat
2. Backend team updates `docs/api_contracts.md` in GitHub
3. Frontend team builds against documented API
4. Frontend team reports issues/bugs
5. Both teams test together before demo

---

## **MVP Checklist**

- [ ] Set up Flutter project
- [ ] Install dependencies
- [ ] Create API config with backend URL
- [ ] Build data models
- [ ] Implement API service
- [ ] Build ReportScreen (submit text reports)
- [ ] Build MapListScreen (view clusters)
- [ ] Build BriefScreen (view brief)
- [ ] Test with real backend
- [ ] Handle errors gracefully
- [ ] Polish UI
- [ ] Test on physical device
- [ ] Prepare demo flow

---

## **Post-MVP Enhancements**

- [ ] Add audio recording
- [ ] Add image capture
- [ ] Add user authentication
- [ ] Add report history
- [ ] Add push notifications for critical events
- [ ] Add offline support
- [ ] Add dark mode
- [ ] Add language localization

---

## **Next Steps**

1. **Set up Flutter project**: `flutter create signalgrid_mobile`
2. **Add dependencies** to pubspec.yaml
3. **Get backend API URL** from backend team
4. **Build data models** based on API responses
5. **Implement API service**
6. **Build screens one by one**
7. **Test with real backend**
8. **Polish and prepare demo**