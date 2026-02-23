require("dotenv").config();
const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const patientRoutes = require("./routes/patientRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/patients", patientRoutes); 

const PORT = 5000;
app.listen(PORT, () => console.log("Server running on port " + PORT));
