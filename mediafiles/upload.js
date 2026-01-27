const multer = require("multer");
const path = require("path");

const storage = multer.diskStorage({
    destination: (req,file,cb)=>{
        cb(null,"uploads/")
    },

    filename:(req,file,cb)=>{
    const ext = path.extname(file.originalname);
        cb(null, Date.now() + file.originalname);
    }

});
const fileFilter = (req,file,cb)=>{
const allowedTypes = /jpeg|jpg|png|gif|mp4|mov|avi|mkv|wav|mp3|wav|mp4a/;
const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
const mimetype = allowedTypes.test(file.mimetype);

if (extname && mimetype) {
cb(null, true);
}else{
cb(new Error("Invalid file type")}
};

const upload = multer({
storage:storage,
fileFilter: fileFilter,
limits: {
fileSize: 1024 * 1024 * 50
}
})

module.exports = {upload};