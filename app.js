require("dotenv").config();
const express = require('express');
const bodyParser = require('body-parser');
const routes = require("./routes/routes");
const cors = require("cors");
const pool = require('./config/database'); // Import PostgreSQL connection

// Initialize Express app
const app = express();
app.use(express.json());
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: true}));

app.get('/', (req, res) => {
    res.json({
        message: 'Welcome to the SignalGrid Backend Lead API',
        status: 'ok',
        endpoints: {
            users: '/api/users',
            reports: '/api/reports',
            briefs: '/api/briefs',
            clusters: '/api/clusters',
            generate_brief: '/api/generate-brief'
        }
    });
});
app.use("/api", routes);

// Start server
app.listen(3008, '0.0.0.0', () => {
    console.log("Your app is running at http://127.0.0.1:3008");
    console.log("Gemini key loaded:", !!process.env.GEMINI_API_KEY);
});