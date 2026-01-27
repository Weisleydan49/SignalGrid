const fs = require("fs");

let express = require('express');
let router = express.Router();
let mongoose = require('mongoose');
let bcrypt = require('bcrypt')
const multer = require('multer');

let Brief = require("../models/Brief");
let Cluster = require("../models/Cluster");
let Event = require("../models/Event");
let Report = require("../models/Report");
let User = require("../models/User");

// const { postImage } = require('../Controller/controller');
const {upload} = require('../mediafiles/upload');
const Media = require("../models/Media");


const EVENT_EXTRACTOR_SYSTEM_PROMPT = require("../service/eventExtractor");
const BRIEF_SYSTEM_PROMPT = require("../service/briefPrompt");
const CLUSTER_SYSTEM_PROMPT = require("../service/briefPrompt");
const genAI = require("../service/genAI")

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

router.post("/user_signup", async (req, res) =>{
    let user = req.body
    let hashed_password = await bcrypt.hash(user.password,10)
    
    user.password = hashed_password;
    user = new User(user);
    try {
        console.log(user)

        let savedUser = await user.save();
        res.status(200).json({"message":"Registration successful"})

    } catch (err){
        console.log("Validation Error for:", user.username);
    // CHANGE 204 TO 400
    res.status(400).json({ 
        "success": false,
        "message": err.message 
    })

  }

});

router.post("/make_report", upload.array('media', 5), async (req, res) => {
    try {
        // 1. Validate
        const { description, evidence_type, user_id, location } = req.body;

        if (evidence_type === "text" && (!description || description.trim() === "")) {
            return res.status(400).json({
                error: "description required for text reports"
            });
        }

        // 2. Save report
        const report = new Report({
            user_id,
            description: description || "",
            evidence_type: evidence_type || "text",
            location
        });

        const savedReport = await report.save();

        // 3. Save media files
        const mediaFiles = [];
        if (req.files && req.files.length > 0) {
            for (const file of req.files) {
                const media = new Media({
                    report_id: savedReport._id,
                    filename: file.filename,
                    file_path: file.path,
                    media_type: getMediaType(file.mimetype)
                });
                const savedMedia = await media.save();
                mediaFiles.push(savedMedia._id);
            }

            savedReport.media_files = mediaFiles;
            await savedReport.save();
        }

        // 4. Prepare Gemini content (multimodal)
        let geminiContent = [];

        if (description && description.trim()) {
            geminiContent.push({ text: description });
        }

        if (req.files && req.files.length > 0) {
            for (const file of req.files) {
                const fileData = fs.readFileSync(file.path);
                const base64Data = fileData.toString("base64");

                geminiContent.push({
                    inlineData: {
                        data: base64Data,
                        mimeType: file.mimetype
                    }
                });
            }
        }

        if (geminiContent.length === 0) {
            return res.status(400).json({
                error: "Report must contain text or media"
            });
        }

        // 5. Call Gemini for event extraction
        const model = genAI.getGenerativeModel({
            model: "gemini-1.5-flash",
            systemInstruction: EVENT_EXTRACTOR_SYSTEM_PROMPT
        });

        const result = await model.generateContent(geminiContent);
        const text = result.response.text();
        const parsed = JSON.parse(text);

        // 6. Get recent events for clustering
        const recentEvents = await Event.find()
            .sort({ createdAt: -1 })
            .limit(20)
            .select("_id event_type location_hint time_hint severity cluster_id");

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
            model: "gemini-1.5-flash",
            systemInstruction: CLUSTER_SYSTEM_PROMPT
        });

        const clusterResult = await clusterModel.generateContent(
            JSON.stringify(clusterPrompt)
        );

        const clusterData = JSON.parse(clusterResult.response.text());

        // 9. Save or update cluster
        let cluster = await Cluster.findOne({ cluster_id: clusterData.cluster_id });

        if (!cluster) {
            cluster = new Cluster(clusterData);
            await cluster.save();
        } else {
            cluster.cluster_summary = clusterData.cluster_summary;
            cluster.trend = clusterData.trend;
            cluster.cluster_severity_1_to_5 = clusterData.cluster_severity_1_to_5;
            cluster.cluster_confidence_0_to_1 = clusterData.cluster_confidence_0_to_1;
            await cluster.save();
        }

        // 10. Save event WITH cluster_id
        const event = new Event({
            report_id: savedReport._id,
            cluster_id: clusterData.cluster_id,
            event_type: parsed.event_type || "other",
            location_hint: parsed.location_hint || "",
            time_hint: parsed.time_hint || "unknown",
            severity: parsed.severity_1_to_5 ?? 1,
            summary: parsed.summary || "",
            confidence: parsed.confidence_0_to_1 ?? 0,
            extracted_json: parsed
        });

        const savedEvent = await event.save();

        // 11. Update cluster's related_event_ids
        if (!cluster.related_event_ids.includes(savedEvent._id.toString())) {
            cluster.related_event_ids.push(savedEvent._id.toString());
            await cluster.save();
        }

        // 12. Response
        res.status(201).json({
            message: "Report created successfully",
            report_id: savedReport._id,
            event_id: savedEvent._id,
            cluster_id: cluster.cluster_id
        });

    } catch (err) {
        console.log(err);
        res.status(500).json({ message: err.message });
    }
});


router.get("/reports", async(req,res) =>{
    console.log("here")
    try {
        let reports = await Report.find()
        res.status(200).json(reports)
        
    } catch (err) {
        res.status(204).json({message:err.message})
        
    }
});

router.get("/briefs", async(req,res) =>{
    console.log("here")
    try {
        let brief = await Brief.find()
        res.status(200).json(briefs)
        
    } catch (err) {
        res.status(204).json({message:err.message})
        
    }
});

router.get("/clusters", async(req,res) =>{
    console.log("here")
    try {
        let clusters = await Cluster.find()
        res.status(200).json(clusters)
        
    } catch (err) {
        res.status(204).json({message:err.message})
        
    }
});


router.get("/users", async(req,res) =>{
    console.log("here")
    try {
        let users = await User.find()
        res.status(200).json(users)
        
    } catch (err) {
        res.status(204).json({message:err.message})
        
    }
});

router.post("/generate-brief", async (req, res) => {
  try {
    const current_clusters = await Cluster.find({ status: "active" }).lean();

    const previous_brief = await Brief.findOne()
      .sort({ createdAt: -1 })
      .lean();

    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
      systemInstruction: BRIEF_SYSTEM_PROMPT
    });

    const result = await model.generateContent(
      JSON.stringify({
        current_clusters,
        previous_brief
      })
    );

    const text = result.response.text();
    const briefData = JSON.parse(text);

    const savedBrief = await Brief.create({
      ...briefData,
      generated_at: new Date()
    });

    res.status(201).json(savedBrief);

  } catch (err) {
    console.error("Gemini briefing error:", err);
    res.status(500).json({
      message: "Failed to generate briefing",
      error: err.message
    });
  }
});


    /* Save brief */
    const savedBrief = await Brief.create({
      ...briefData,
      generated_at: new Date()
    });

    /* Respond */
    res.status(201).json(savedBrief);

  } catch (err) {
    console.error("Gemini briefing error:", err);
    res.status(500).json({
      message: "Failed to generate briefing",
      error: err.message
    });
  }
});

module.exports = router;

