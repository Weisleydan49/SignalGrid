let mongoose = require("mongoose");

let event_schema = mongoose.Schema({
    report_id: {
        type: mongoose.Types.ObjectId,
        ref: "Report",
        required: true
    },
    event_type: {
        type: String,
        required: true
    },
    location_hint: {
        type: String,
        required: true
    },
    time_hint: {
        type: String,
        required: true,
        default:Date.now
    },
    severity:{
        type: String,
        required: true
    },
    summary: {
        type: String,
        required: true
    },
    confidence: {
        type: String,
        required: true
    },
    extracted_json: {
        type: mongoose.Schema.Types.Mixed
    }

},{
  timestamps: true});


module.exports = mongoose.model("Event", event_schema)