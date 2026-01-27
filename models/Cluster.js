let mongoose = require("mongoose");


let cluster_schema = mongoose.Schema({
  cluster_id: {
    type: String,
    required: true,
    unique: true, // ensures each cluster has a unique ID
  },
  cluster_label: {
    type: String,
    required: true,
    trim: true,
  },
  cluster_summary: {
    type: String,
    required: true,
    trim: true,
  },
  cluster_severity_1_to_5: {
    type: Number,
    required: true,
    min: 1,
    max: 5,
    default: 1,
  },
  cluster_confidence_0_to_1: {
    type: Number,
    required: true,
    min: 0,
    max: 1,
    default: 0,
  },
  trend: {
    type: String,
    enum: ["emerging", "stable", "escalating", "resolving"],
    required: true,
    default: "emerging",
  },
  related_event_ids: {
    type: [String], // array of event IDs
    default: [],
  },
  rationale: {
    type: String,
    required: true,
    trim: true,
    default: "",
  },
}, {
  timestamps: true, // adds createdAt and updatedAt automatically
});


module.exports = mongoose.model("Cluster", cluster_schema)

