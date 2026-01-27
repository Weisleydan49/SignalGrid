let mongoose = require("mongoose");

let image_schema = mongoose.Schema({
    report_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Report",
    required: true
    },
    filename:{
        type: String,
        required: true,
    },
    file_path: {
        type: String,
        required: true,
    },
    media_type: {
    type: String,
    required: true,
    enum: ['image', 'video', 'audio']
    },
    uploadedAt: {
        type: String,
        required: true,
        default:Date.now
    } 
    
});


module.exports = mongoose.model("Image", image_schema)