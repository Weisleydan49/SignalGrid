let mongoose = require("mongoose");

let brief_schema = mongoose.Schema({
    created_at: {
        type: String,
        required: true,
        default:Date.now
    },
    brief_json: {
        type: String,
        required: true
    }
});


module.exports = mongoose.model("Brief", brief_schema)