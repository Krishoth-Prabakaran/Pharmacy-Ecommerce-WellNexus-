// backend/server.js
require("dotenv").config();
const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const patientRoutes = require("./routes/patientRoutes");
const pharmacyRoutes = require("./routes/pharmacyRoutes");
const doctorRoutes = require("./routes/doctorRoutes");

const app = express();

// Enhanced CORS configuration
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:5000', 'http://127.0.0.1:5000'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/patients", patientRoutes); 
app.use("/api/pharmacies", pharmacyRoutes);
app.use("/api/doctors", doctorRoutes);

// Test route
app.get("/api/test", (req, res) => {
  res.json({ 
    message: "Server is running!",
    timestamp: new Date().toISOString(),
    endpoints: {
      auth: "/api/auth",
      patients: "/api/patients",
      doctors: "/api/doctors",
      pharmacies: "/api/pharmacies"
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    message: `Route ${req.url} not found` 
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("❌ Server error:", err);
  res.status(500).json({ 
    success: false, 
    message: "Internal server error",
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`   Test: http://localhost:${PORT}/api/test`);
  console.log(`   Auth: http://localhost:${PORT}/api/auth`);
});