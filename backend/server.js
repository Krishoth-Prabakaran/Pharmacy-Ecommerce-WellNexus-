require("dotenv").config();
const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const patientRoutes = require("./routes/patientRoutes");
const pharmacyRoutes = require("./routes/pharmacyRoutes");
const doctorRoutes = require("./routes/doctorRoutes"); // ADD THIS LINE

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/patients", patientRoutes); 
app.use("/api/pharmacies", pharmacyRoutes);
app.use("/api/doctors", doctorRoutes); // ADD THIS LINE

// Optional: Add a test route to verify server is running
app.get("/api/test", (req, res) => {
  res.json({ message: "Server is running!" });
});

const PORT = 5000;
app.listen(PORT, () => console.log("Server running on port " + PORT));