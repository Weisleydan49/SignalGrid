let mongoose = require("mongoose");

let report_schema = mongoose.Schema({
    user_id:{
        type: mongoose.Types.ObjectId,
        ref: "User",
        required: true

    },
    description: {
        type: String,
        required: true,
    },

    evidence_type: {
        type: String,
        required: true,
        enum: ['text', 'image', 'video', 'audio']
    },

    media_files: [{
    type: mongoose.Types.ObjectId,
    ref: "Media"
    }],

    // image_id: [{
    //     type: mongoose.Types.ObjectId,
    //     ref: "Image",
    //     required: true
    // }] ,  
    location: {
      type: String,
      required: true
    
    },
    created_at: {
        type: String,
        required: true,
        default:Date.now
    }
});


module.exports = mongoose.model("Report", report_schema)