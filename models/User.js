let mongoose = require("mongoose");
let uniqueValidator = require("mongoose-unique-validator");

let user_schema = mongoose.Schema({
    username: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    status: {
        type: Number,
        default: 1,
        required: true
    },
    phone_no: {
        type: String,
        required: true
    },
    password: {
        type: String,
        required: true
    },
    reg_date: {
        type: String,
        required: true,
        default:Date.now
    }
});

user_schema.plugin(uniqueValidator,{"message": "Email is already in use"})
module.exports = mongoose.model("User", user_schema)