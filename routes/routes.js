const pool = require('../config/database');
const fs = require("fs");
let express = require('express');
let router = express.Router();
let bcrypt = require('bcrypt')
const multer = require('multer');

// const { postImage } = require('../Controller/controller');
const {upload} = require('../mediafiles/upload');
const Media = require("../models/Media");


const EVENT_EXTRACTOR_SYSTEM_PROMPT = require("../service/eventExtractor");
const BRIEF_SYSTEM_PROMPT = require("../service/briefPrompt");
const CLUSTER_SYSTEM_PROMPT = require("../service/clusterPrompt");
const genAI = require("../service/genAI");
const { report } = require('process');
const cluster = require('cluster');

function getMediaType(mimetype) {
    switch (mimetype) {
    case 'image/jpeg':
    case 'image/png':
    case 'image/gif':
        return 'image';
    case 'video/mp4':
    case 'video/mov':
    case 'video/avi':
    case 'video/mkv':
        return 'video';
    case 'audio/mp3':
    case 'audio/wav':
    case 'audio/mp4':
        return 'audio';
    default:
        return 'unknown';
    }
}

// console.log('Is upload a function?', typeof upload.single === 'function');

// router.post("/", upload.single("image",postImage));

router.post("/user_signup", async (req, res) => {
    try {
    const { username, password } = req.body;
    const hashed_password = await bcrypt.hash(password, 10);

    await pool.query(
    `INSERT INTO users (username, password)
    VALUES ($1, $2)`,
    [username, hashed_password]
    );

    res.status(200).json({ message: "Registration successful" });

} catch (err) {
    res.status(400).json({
      success: false,
      message: err.message
    });
  }
});


router.post("/make_report", upload.array('media', 5), async (req, res) => {
    try {
        // 1. Validate
        const { description, evidence_type, user_id, location} = req.body;

        if (evidence_type === "text" && (!description || description.trim() === "")) {
            return res.status(400).json({
                error: "description required for text reports"
            });
        }

        // 2. Save report
        const reportResult = await pool.query(
    `INSERT INTO public.reports (user_id, description, evidence_type, location)
    VALUES ($1, $2, $3, $4)
    RETURNING id`,
    [
    user_id || 1,
    description || "",
    evidence_type || "text",
    location || "unknown"
    ]
);


        const reportId = reportResult.rows[0].id;
        // 3. Save media files
        const mediaFiles = [];
        if (req.files && req.files.length > 0) {
    for (const file of req.files) {
        await pool.query(
            `INSERT INTO public.media
            (report_id, filename, file_path, media_type)
            VALUES ($1,$2,$3,$4)`,
            [
                reportId,
                file.filename,
                file.path,
                getMediaType(file.mimetype)
            ]
        );
    }
}


        // 4. Prepare Gemini input with structured data
const currentTime = new Date().toISOString();
const geminiInput = {
  current_time: currentTime,
  description: description || "",
  location: location || "unknown",
  time_hint: req.body.time_hint || "just now"
};

// 5. Call Gemini
const model = genAI.getGenerativeModel({
  model: "gemini-3-flash-preview",
  systemInstruction: EVENT_EXTRACTOR_SYSTEM_PROMPT
});

const result = await model.generateContent(JSON.stringify(geminiInput));
const text = result.response.text();

console.log("=== GEMINI RAW OUTPUT ===");
console.log(text);
console.log("========================");

// Clean response before parsing
let cleanText = text.trim();
if (cleanText.startsWith('```json')) {
    cleanText = cleanText.replace(/```json\n?/g, '').replace(/```\n?$/g, '');
}

const parsed = JSON.parse(cleanText);

        // 6. Get recent events for clustering
        const eventsResult = await pool.query(
            `SELECT id, event_type, location_hint,
            time_hint, severity, cluster_id
            FROM events
            ORDER BY created_at DESC
            LIMIT 20`
        );
        const recentEvents = eventsResult.rows;

        // 7. Prepare clustering prompt
        const clusterPrompt = {
            new_event: {
                event_type: parsed.event_type || "other",
                location_hint: parsed.location_hint || "",
                time_hint: parsed.time_hint || "unknown",
                severity_1_to_5: parsed.severity_1_to_5 ?? 1
            },
            recent_events: recentEvents.map(e => ({
                id: e._id,
                event_type: e.event_type,
                location_hint: e.location_hint,
                time_hint: e.time_hint,
                cluster_id: e.cluster_id || null
            }))
        };

        // 8. Call Gemini for clustering
        const clusterModel = genAI.getGenerativeModel({
            model: "gemini-3-flash-preview",
            systemInstruction: CLUSTER_SYSTEM_PROMPT
        });

        const clusterResult = await clusterModel.generateContent(
            JSON.stringify(clusterPrompt)
        );

        const clusterData = JSON.parse(clusterResult.response.text());

        console.log("Cluster Data from Gemini:", clusterData);


        if (!clusterData.cluster_id) {
            clusterData.cluster_id = `cluster_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
        }
        // 9. Save or update cluster
        const clusterCheck = await pool.query(
  "SELECT * FROM clusters WHERE cluster_id=$1",
  [clusterData.cluster_id]
);

if (clusterCheck.rows.length === 0) {
    await pool.query(
        `INSERT INTO clusters
        (cluster_id, cluster_label, cluster_summary, trend,
        cluster_severity_1_to_5, cluster_confidence_0_to_1, rationale)
        VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [
        clusterData.cluster_id,
        clusterData.cluster_label ||'',
        clusterData.cluster_summary,
        clusterData.trend,
        clusterData.cluster_severity_1_to_5,
        clusterData.cluster_confidence_0_to_1,
        clusterData.rationale || ''
        ]
    );
} else {
    await pool.query(
        `UPDATE clusters
        SET cluster_label=$1,
        cluster_summary=$2,
            trend=$3,
            cluster_severity_1_to_5=$4,
            cluster_confidence_0_to_1=$5,
            rationale=$6,
            updated_at=NOW()
            WHERE cluster_id=$7`,
        [
        clusterData.cluster_label ||'',
        clusterData.cluster_summary,
        clusterData.trend,
        clusterData.cluster_severity_1_to_5,
        clusterData.cluster_confidence_0_to_1,
        clusterData.rationale || '',
        clusterData.cluster_id
        ]
    );
}

        // 10. Save event WITH cluster_id
        const eventResult = await pool.query(
            `INSERT INTO events
            (report_id, cluster_id, event_type, location_hint,
            time_hint, severity, summary, confidence)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
            RETURNING id`,
            [
                
                reportId,
                clusterData.cluster_id,
                parsed.event_type || "other",
                parsed.location_hint || "",
                parsed.time_hint || "unknown",
                parsed.severity_1_to_5 ?? 1,
                parsed.summary || "",
                parsed.confidence_0_to_1 ?? 0
            ]
        );

        const savedEventId = eventResult.rows[0].id;

        // 11. Update cluster's related_event_ids
        const clusterUpdateResult = await pool.query(
            `SELECT related_event_ids FROM clusters WHERE cluster_id=$1`,
            [clusterData.cluster_id]
        );
        let relatedEventIds = clusterUpdateResult.rows[0].related_event_ids || [];

        if (!relatedEventIds.includes(savedEventId.toString())) {
            relatedEventIds.push(savedEventId.toString());
            await pool.query(
                `UPDATE clusters SET related_event_ids=$1 WHERE cluster_id=$2`,
                [JSON.stringify(relatedEventIds), clusterData.cluster_id]
            );
        }

        // 12. Response
        res.status(201).json({
    message: "Report created successfully",
    report_id: reportId,
    event_id: savedEventId,
    cluster_id: clusterData.cluster_id,
    event_type: parsed.event_type || "other",
    location_hint: parsed.location_hint || "",
    time_hint: parsed.time_hint || "unknown",
    severity: parsed.severity_1_to_5 ?? 1,
    summary: parsed.summary || "",
    confidence: parsed.confidence_0_to_1 ?? 0
});

    } catch (err) {
        console.log(err);
        res.status(500).json({ message: err.message });
    }
});


router.get("/reports", async(req,res) =>{
    console.log("here")
    try {
        const result = await pool.query('SELECT * FROM reports ORDER BY created_at DESC');
        res.status(200).json(result.rows)
    } catch (err) {
        res.status(500).json({message:err.message})
        
    }
});

router.get("/briefs", async(req,res) =>{
    console.log("here")
    try {
        const result = await pool.query('SELECT * FROM briefs ORDER BY created_at DESC');
        const briefs = result.rows.map(brief => ({
            ...brief,
            brief_json: typeof brief.brief_json === 'string' ?
            JSON.parse(brief.brief_json)
            : brief.brief_json
        }))
        res.status(200).json(briefs)
    } catch (err) {
        res.status(500).json({message:err.message})
        
    }
});

router.get("/clusters", async(req,res) =>{
    console.log("here")
    try {
        const result = await pool.query('SELECT * FROM clusters ORDER BY created_at DESC');
        console.log("Clusters found:", result.rows.length);
        console.log("First cluster:", result.rows[0]);
        res.status(200).json(result.rows);
    } catch (err) {
        console.log("Cluster error:", err);
        res.status(500).json({message:err.message})
    }
});

router.get("/users", async(req,res) =>{
    console.log("here")
    try {
        const result = await pool.query("SELECT * FROM users");
        res.status(200).json(result.rows)
        
    } catch (err) {
        res.status(500).json({message:err.message})
        
    }
});

router.post("/generate-brief", async (req, res) => {
  try {
    // Fetch active clusters and previous brief in parallel for better performance
    const [clustersResult, briefResult] = await Promise.all([
    pool.query("SELECT * FROM clusters"),
    pool.query("SELECT * FROM briefs ORDER BY created_at DESC LIMIT 1")
    ]);
    const current_clusters = clustersResult.rows;
    const previous_brief = briefResult.rows[0] || null;

    // Prepare and call Gemini for briefing

    const model = genAI.getGenerativeModel({
    model: "gemini-3-flash-preview",
    systemInstruction: BRIEF_SYSTEM_PROMPT
    });

    const result = await model.generateContent(
        JSON.stringify({
        current_clusters,
        previous_brief
    })
    );

    const text = result.response.text();
    
    // Add error handling for JSON parsing
    let briefData;
    try {
        briefData = JSON.parse(text);
    } catch (parseError) {
        console.error("JSON parse error:", text);
        throw new Error("Invalid JSON response from AI model");
    }

    // Save the brief
    const insertResult = await pool.query(
    `
    INSERT INTO briefs (brief_json, created_at)
    VALUES ($1, NOW())
  RETURNING *
    `,
    [JSON.stringify(briefData)]
);


res.status(201).json(insertResult.rows[0]);

    } catch (err) {
    console.error("Gemini briefing error:", err);
    res.status(500).json({
    message: "Failed to generate briefing",
    error: err.message
    });
    }
});

module.exports = router;