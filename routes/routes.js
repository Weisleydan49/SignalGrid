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
// const {upload} = require('../Images/upload');

const EVENT_EXTRACTOR_SYSTEM_PROMPT = require("../service/eventExtractor");
const BRIEF_SYSTEM_PROMPT = require("../service/briefPrompt");
const CLUSTER_SYSTEM_PROMPT = require("../service/briefPrompt");
const genAI = require("../service/genAI")
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

router.post("/make_report", async (req,res) => {
    let report = req.body
    try {
        let newReport = new Report(report)
        let savedReport = await newReport.save();
        
        const { description } = req.body;

        if (typeof description !== "string" || description.trim() === "") {
            return res.status(400).json({
            error: "description must be a non-empty string"
        });
}

            const model = genAI.getGenerativeModel({
            model: "gemini-3-flash-preview",
            systemInstruction: EVENT_EXTRACTOR_SYSTEM_PROMPT
        });


        const result = await model.generateContent(description);
        const text = result.response.text();

        const parsed = JSON.parse(text);
        // res.json(parsed);

      // 4. Save event
        const event = await new Event({
            report_id: savedReport._id,
            event_type: parsed.event_type || "other",
            location_hint: parsed.location_hint || "",
            time_hint: parsed.time_hint || "unknown",
            severity: parsed.severity_1_to_5 ?? 1,        // map Gemini -> Mongoose
            summary: parsed.summary || "",
            confidence: parsed.confidence_0_to_1 ?? 0,   // map Gemini -> Mongoose
            extracted_json: parsed
        }).save();


      const savedEvent = await event.save();

      res.status(201).json({
        message: "Report created successfully",
        // report_id: savedReport._id,
        // // image_id: savedImage ? savedImage._id : null,
        // event_id:savedEvent._id
      })

    } catch (err) {
        console.log(err)
        res.status(500).json({message:err.message})
        
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

router.post("/cluster_event", async (req, res) => {
  try {
    // // 1. Get the new event
    const newEvent = await Event.findOne().sort({ createdAt: -1 });

    if (!newEvent) {
      return res.status(404).json({ message: "No events found in database" });
    }

    // 2. Get last 20 recent events (excluding this one)
    const recentEvents = await Event.find({
      _id: { $ne: newEvent._id }
    })
      .sort({ createdAt: -1 })
      .limit(20)
      .select("_id event_type location_hint time_hint severity_1_to_5 cluster_id");

    // 3. Prepare Gemini input
    const promptInput = {
      new_event: {
        id: newEvent._id,
        event_type: newEvent.event_type,
        location_hint: newEvent.location_hint,
        time_hint: newEvent.time_hint,
        severity_1_to_5: newEvent.severity_1_to_5
      },
      recent_events: recentEvents.map(e => ({
        id: e._id,
        event_type: e.event_type,
        location_hint: e.location_hint,
        time_hint: e.time_hint,
        cluster_id: e.cluster_id || null
      }))
    };

    // 4. Call Gemini
    const response = await genAI.models.generateContent({
      model: "gemini-3-flash-preview",
      systemInstruction: CLUSTER_SYSTEM_PROMPT,
      contents: JSON.stringify(promptInput)
    });

    const clusterResult = JSON.parse(response.text);

    // 5. Save / update cluster
    let cluster = await Cluster.findOne({ cluster_id: clusterResult.cluster_id });

    if (!cluster) {
      cluster = new Cluster(clusterResult);
    } else {
      cluster.related_event_ids = clusterResult.related_event_ids;
      cluster.trend = clusterResult.trend;
      cluster.cluster_summary = clusterResult.cluster_summary;
    }

    await cluster.save();

    // 6. Update all related events with cluster_id
    await Event.updateMany(
      { _id: { $in: clusterResult.related_event_ids } },
      { $set: { cluster_id: clusterResult.cluster_id } }
    );

    res.status(200).json({
      message: "Event clustered successfully",
      cluster
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: err.message });
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
      systemInstruction: SYSTEM_PROMPT
    });

    /* Send ONLY structured input */
    const result = await model.generateContent(
      JSON.stringify({
        current_clusters,
        previous_brief
      })
    );

    const text = result.response.text();

    /* Parse strict JSON */
    const briefData = JSON.parse(text);

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

