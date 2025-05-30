require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const admin = require('firebase-admin');
const serviceAccount = require('./firbases/firbase_key.json'); // Ensure this path and file exist

const app = express();

// Firebase Admin initialization
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

app.use(cors());
app.use(cookieParser());
app.use(express.json()); // Required for POST requests

// Routes
const googleRoutes = require('./routes/google');
const analyticsRoutes = require('./routes/analytics');

app.use('/api/google', googleRoutes);
app.use('/api/analytics', analyticsRoutes);

// Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));