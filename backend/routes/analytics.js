const express = require('express');
const router = express.Router();
const controller = require('../controllers/analyticsController');
const attendanceService = require('../services/attendanceService');

// GET: Overview analytics for HR dashboard
router.get('/overview', controller.getOverviewAnalytics);

// POST: Mark attendance with buffer time check + team lead notification
router.post('/mark', async (req, res) => {
  const { userId, timestamp } = req.body;

  if (!userId || !timestamp) {
    return res.status(400).json({ error: 'Missing userId or timestamp' });
  }

  try {
    const record = await attendanceService.markAttendanceWithBufferCheck(userId, timestamp);
    res.status(200).json({ message: 'Attendance recorded', record });
  } catch (error) {
    console.error('Attendance error:', error);
    res.status(500).json({ error: 'Failed to record attendance' });
  }
});

// POST: Invisible attendance via Wi-Fi or geofence
router.post('/invisible', async (req, res) => {
  const { userId, ssid, lat, lon, timestamp } = req.body;

  if (!userId || !timestamp) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  try {
    const record = await attendanceService.markInvisibleAttendance(userId, ssid, lat, lon, timestamp);
    res.status(200).json({ message: 'Invisible attendance marked', record });
  } catch (error) {
    console.error('Invisible attendance error:', error);
    res.status(403).json({ error: error.message });
  }
});

// POST: Start focus session
router.post('/focus/start', async (req, res) => {
  const { userId, timestamp } = req.body;

  if (!userId || !timestamp) {
    return res.status(400).json({ error: 'Missing userId or timestamp' });
  }

  try {
    await attendanceService.startFocusTime(userId, timestamp);
    res.status(200).json({ message: 'Focus session started' });
  } catch (error) {
    console.error('Focus start error:', error);
    res.status(500).json({ error: 'Failed to start focus session' });
  }
});

// POST: Stop focus session
router.post('/focus/stop', async (req, res) => {
  const { userId, timestamp } = req.body;

  if (!userId || !timestamp) {
    return res.status(400).json({ error: 'Missing userId or timestamp' });
  }

  try {
    await attendanceService.stopFocusTime(userId, timestamp);
    res.status(200).json({ message: 'Focus session stopped and logged' });
  } catch (error) {
    console.error('Focus stop error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;