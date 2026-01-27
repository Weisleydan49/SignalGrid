require("dotenv").config(); 
let mongoose = require('mongoose')
let express = require('express')
const bodyParser = require('body-parser');
let routes = require("./routes/routes")
const path = require('path')
let cors = require("cors")




mongoose.connect("mongodb://localhost:27017/signalgrid_db",{ useNewUrlParser:true})
.then(()=>{

    // initialize Express app
    let app = express()
    app.use(express.json())
    app.use(cors())
    app.use(bodyParser.json())
    app.use(bodyParser.urlencoded({extended: true}))
    app.use("/api",routes)
    app.listen(3008,()=>{
        console.log("Your app is running at http://127.0.0.1:3008")
    })
    console.log("Gemini key loaded:", !!process.env.GEMINI_API_KEY);



  
})