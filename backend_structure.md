# SignalGrid Backend Structure (Node.js + Express + MongoDB)

## **Project Folder Structure**

```
signalgrid_backend/
├── src/
│   ├── config/
│   │   ├── database.js          // MongoDB connection
│   │   ├── gemini.js            // Gemini AI client setup
│   │   └── env.js               // Environment variables
│   │
│   ├── models/
│   │   ├── User.js              // User schema (optional for MVP)
│   │   ├── Report.js            // Raw report schema
│   │   ├── Event.js             // Extracted event schema
│   │   ├── Cluster.js           // Event cluster schema
│   │   └── Brief.js             // Situation brief schema
│   │
│   ├── controllers/
│   │   ├── authController.js    // Register, login (optional for MVP)
│   │   ├── reportController.js  // Submit reports
│   │   ├── cycleController.js   // AI cycle runner
│   │   ├── clusterController.js // Get clusters
│   │   └── briefController.js   // Get briefs
│   │
│   ├── services/
│   │   ├── geminiService.js     // Gemini API client wrapper
│   │   ├── eventExtractor.js    // Event extraction logic
│   │   ├── clusterer.js         // Clustering logic
│   │   └── briefGenerator.js    // Brief generation logic
│   │
│   ├── middleware/
│   │   ├── auth.js              // JWT verification (optional for MVP)
│   │   ├── validation.js        // Input validation
│   │   └── errorHandler.js      // Error handling
│   │
│   ├── routes/
│   │   ├── auth.js              // Auth endpoints (optional)
│   │   ├── reports.js           // Report endpoints
│   │   ├── cycle.js             // Cycle endpoints
│   │   ├── clusters.js          // Cluster endpoints
│   │   └── briefs.js            // Brief endpoints
│   │
│   └── app.js                   // Express setup
│
├── .env.example
├── package.json
└── server.js                    // Entry point
```

---

## **File Descriptions**

### **config/**
- **database.js**: MongoDB connection logic using Mongoose
- **gemini.js**: Initialize Gemini AI client with API key
- **env.js**: Load and validate environment variables

### **models/**
MongoDB schemas using Mongoose:

- **Report.js**: Stores raw user reports
  - Fields: `raw_text`, `evidence_type`, `created_at`
  
- **Event.js**: Stores extracted structured events
  - Fields: `report_id`, `event_type`, `location_hint`, `time_hint`, `severity`, `summary`, `confidence`, `extracted_json`
  
- **Cluster.js**: Stores event clusters
  - Fields: `cluster_id`, `label`, `summary`, `severity`, `confidence`, `trend`, `related_event_ids`, `updated_at`, `cluster_json`
  
- **Brief.js**: Stores situation briefs
  - Fields: `created_at`, `brief_json`

- **User.js** (optional): User authentication
  - Fields: `username`, `email`, `password_hash`

### **controllers/**
Handle incoming HTTP requests and send responses:

- **reportController.js**: 
  - `submitReport()`: Receive report, save to DB, call event extractor, return event JSON
  
- **cycleController.js**: 
  - `runAICycle()`: Load last 20 events, cluster them, generate brief, save results
  
- **clusterController.js**: 
  - `getAllClusters()`: Return all active clusters
  - `getClusterById()`: Return specific cluster
  
- **briefController.js**: 
  - `getLatestBrief()`: Return most recent brief
  - `getAllBriefs()`: Return all briefs (for history)

- **authController.js** (optional):
  - `register()`: Create new user
  - `login()`: Authenticate and return JWT token

### **services/**
Business logic and external API calls:

- **geminiService.js**: Wrapper for Gemini API client
  - `callGemini(prompt, input)`: Generic function to call Gemini
  
- **eventExtractor.js**: 
  - `extractEvent(reportText)`: Call Gemini with Event Extractor prompt
  
- **clusterer.js**: 
  - `clusterEvent(newEvent, recentEvents)`: Call Gemini with Clusterer prompt
  
- **briefGenerator.js**: 
  - `generateBrief(clusters, previousBrief)`: Call Gemini with Brief Generator prompt

### **middleware/**
Functions that run before controllers:

- **auth.js**: Verify JWT tokens for protected routes
- **validation.js**: Validate request body structure
- **errorHandler.js**: Catch and format errors

### **routes/**
Define API endpoints and connect to controllers:

- **reports.js**: Report submission endpoints
- **cycle.js**: AI cycle trigger endpoints
- **clusters.js**: Cluster retrieval endpoints
- **briefs.js**: Brief retrieval endpoints
- **auth.js**: Authentication endpoints

---

## **API Endpoints**

### **Reports & AI Cycle**
| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | `/api/reports` | Submit incident report | `{ "text": "string", "evidence_type": "text\|audio\|image" }` | Event JSON |
| POST | `/api/cycle/run` | Run AI clustering + brief generation | None | `{ "clusters": [...], "brief": {...} }` |
| GET | `/api/clusters` | Get all current clusters | None | Array of clusters |
| GET | `/api/clusters/:id` | Get specific cluster | None | Single cluster object |
| GET | `/api/briefs/latest` | Get latest situation brief | None | Brief object |
| GET | `/api/briefs` | Get all briefs (history) | None | Array of briefs |

### **Authentication (Optional for MVP)**
| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| POST | `/api/auth/register` | User registration | `{ "email": "string", "password": "string" }` | User object + token |
| POST | `/api/auth/login` | User login | `{ "email": "string", "password": "string" }` | Token |

---

## **Data Flow**

1. **User submits incident report** (text/image/audio) via Flutter
2. **POST /api/reports** → `reportController.submitReport()`
3. Controller saves report to MongoDB → `Report` collection
4. Controller calls `eventExtractor.extractEvent(reportText)`
5. Service calls Gemini with Event Extractor prompt
6. Gemini returns structured event JSON
7. Controller saves event to MongoDB → `Event` collection
8. Controller returns event JSON to Flutter
9. **User or auto-trigger calls POST /api/cycle/run** → `cycleController.runAICycle()`
10. Controller loads last 20 events from MongoDB
11. Controller calls `clusterer.clusterEvent(latestEvent, recentEvents)`
12. Service calls Gemini with Clusterer prompt
13. Gemini returns cluster decision
14. Controller updates/creates cluster in MongoDB → `Cluster` collection
15. Controller loads all current clusters
16. Controller calls `briefGenerator.generateBrief(clusters, previousBrief)`
17. Service calls Gemini with Brief Generator prompt
18. Gemini returns situation brief
19. Controller saves brief to MongoDB → `Brief` collection
20. Controller returns clusters + brief to Flutter
21. **Flutter displays results**

---

## **Environment Variables (.env.example)**

```
# Server
PORT=5000
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb://localhost:27017/signalgrid_db
# OR for MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/signalgrid_db

# Gemini AI
GEMINI_API_KEY=your_gemini_api_key_here

# JWT (optional for auth)
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRES_IN=7d
```

---

## **Dependencies (package.json)**

```json
{
  "name": "signalgrid-backend",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^8.0.0",
    "dotenv": "^16.3.1",
    "@google/generative-ai": "^0.1.3",
    "cors": "^2.8.5",
    "express-validator": "^7.0.0",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3"
  },
  "devDependencies": {
    "nodemon": "^3.0.0"
  }
}
```

---

## **Deployment Checklist**

### **For Railway/Render:**

1. **Set up MongoDB Atlas** (cloud database)
   - Create free cluster
   - Get connection string
   - Whitelist all IPs (0.0.0.0/0) for development

2. **Deploy Backend**
   - Push code to GitHub
   - Connect repo to Railway/Render
   - Set environment variables:
     - `MONGODB_URI`
     - `GEMINI_API_KEY`
     - `JWT_SECRET`
     - `PORT`
   - Deploy

3. **Test Endpoints**
   - Use Postman to test all endpoints
   - Verify database connections
   - Check Gemini API calls work

4. **Share with Frontend Team**
   - Provide base URL (e.g., `https://signalgrid-api.onrender.com`)
   - Provide API documentation
   - Provide example requests/responses

---

## **MongoDB Collections Schema**

### **reports**
```javascript
{
  _id: ObjectId,
  raw_text: String,
  evidence_type: String, // "text", "audio", "image", "video"
  created_at: Date
}
```

### **events**
```javascript
{
  _id: ObjectId,
  report_id: ObjectId, // Reference to Report
  event_type: String,
  location_hint: String,
  time_hint: String,
  severity: Number, // 1-5
  summary: String,
  confidence: Number, // 0.0-1.0
  extracted_json: Object, // Full JSON from Gemini
  created_at: Date
}
```

### **clusters**
```javascript
{
  _id: ObjectId,
  cluster_id: String, // "CL-001", "CL-002"
  label: String,
  summary: String,
  severity: Number, // 1-5
  confidence: Number, // 0.0-1.0
  trend: String, // "emerging", "stable", "escalating", "resolving"
  related_event_ids: [String],
  cluster_json: Object, // Full JSON from Gemini
  updated_at: Date
}
```

### **briefs**
```javascript
{
  _id: ObjectId,
  brief_json: Object, // Full JSON from Gemini
  created_at: Date
}
```

---

## **Testing Strategy**

### **Unit Tests**
- Test each service function independently
- Mock Gemini API responses

### **Integration Tests**
- Test full endpoint flows
- Test database operations

### **Manual Testing with Postman**
1. Submit 5 different reports
2. Run cycle after each 2 reports
3. Verify clusters form correctly
4. Verify brief updates with new information
5. Test with contradicting reports

---

## **Next Steps**

1. Set up MongoDB (local or Atlas)
2. Install dependencies
3. Configure .env file
4. Test Gemini prompts in AI Studio first
5. Implement services to call Gemini
6. Build controllers and routes
7. Deploy to Railway/Render
8. Test all endpoints
9. Document API for frontend team