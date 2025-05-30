const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const db = admin.firestore();

const BUFFER_TIME = "09:30"; // 24-hour format
const OFFICE_SSIDS = process.env.OFFICE_SSIDS?.split(',') || [];
const OFFICE_LAT = parseFloat(process.env.OFFICE_LAT);
const OFFICE_LON = parseFloat(process.env.OFFICE_LON);
const GEOFENCE_RADIUS_METERS = parseFloat(process.env.GEOFENCE_RADIUS_METERS || "100");

function parseTime(timeStr) {
  const [hours, minutes] = timeStr.split(":").map(Number);
  return hours * 60 + minutes;
}

function getDistanceFromLatLonInMeters(lat1, lon1, lat2, lon2) {
  const toRad = (val) => (val * Math.PI) / 180;
  const R = 6371000; // Earth radius in meters
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

async function getTeamLeadForUser(userId) {
  const userDoc = await db.collection("users").doc(userId).get();
  const userData = userDoc.data();
  const teamLeadId = userData.teamLeadId;

  if (!teamLeadId) return null;

  const teamLeadDoc = await db.collection("users").doc(teamLeadId).get();
  return teamLeadDoc.exists ? teamLeadDoc.data() : null;
}

async function sendLateNotification(email, name, minutesLate) {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.MAIL_USER,
      pass: process.env.MAIL_PASS,
    },
  });

  const mailOptions = {
    from: process.env.MAIL_USER,
    to: email,
    subject: 'Late Attendance Alert',
    text: `${name} marked attendance late by ${minutesLate} minutes.`,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`Late email sent to ${email}`);
  } catch (err) {
    console.error('Failed to send email:', err);
  }
}

exports.getAllUsers = async () => {
  const snapshot = await db.collection('users').get();
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

exports.getAttendanceForDate = async (date) => {
  const snapshot = await db.collection('attendance_logs')
    .where('date', '==', date)
    .get();

  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

exports.markAttendanceWithBufferCheck = async (userId, timestamp) => {
  const dateObj = new Date(timestamp);
  const currentTime = parseTime(dateObj.toTimeString().substring(0, 5));
  const bufferTime = parseTime(BUFFER_TIME);

  const isLate = currentTime > bufferTime;
  const lateByMinutes = isLate ? currentTime - bufferTime : 0;

  const attendanceDoc = {
    userId,
    date: dateObj.toISOString().split("T")[0],
    time: dateObj.toTimeString().substring(0, 5),
    isLate,
    lateByMinutes,
    timestamp: admin.firestore.Timestamp.fromDate(dateObj),
  };

  await db.collection("attendance_logs").add(attendanceDoc);

  if (isLate) {
    const teamLead = await getTeamLeadForUser(userId);
    const user = await db.collection("users").doc(userId).get();
    const userName = user.exists ? user.data().name : userId;

    if (teamLead?.email) {
      await sendLateNotification(teamLead.email, userName, lateByMinutes);
    }
  }

  return attendanceDoc;
};

exports.markInvisibleAttendance = async (userId, ssid, lat, lon, timestamp) => {
  const dateObj = new Date(timestamp);
  const matchedSSID = ssid && OFFICE_SSIDS.includes(ssid);
  const withinGeofence = lat && lon && getDistanceFromLatLonInMeters(lat, lon, OFFICE_LAT, OFFICE_LON) <= GEOFENCE_RADIUS_METERS;

  if (!matchedSSID && !withinGeofence) {
    throw new Error("Not within authorized Wi-Fi or geofence zone.");
  }

  const attendanceDoc = {
    userId,
    date: dateObj.toISOString().split("T")[0],
    time: dateObj.toTimeString().substring(0, 5),
    method: matchedSSID ? 'Wi-Fi' : 'Geofence',
    isLate: false,
    timestamp: admin.firestore.Timestamp.fromDate(dateObj),
  };

  await db.collection("attendance_logs").add(attendanceDoc);

  return attendanceDoc;
};

exports.startFocusTime = async (userId, timestamp) => {
  const date = new Date(timestamp).toISOString().split("T")[0];
  const docRef = db.collection("focus_logs").doc(`${userId}_${date}`);

  await docRef.set({
    userId,
    date,
    focusStart: admin.firestore.Timestamp.fromDate(new Date(timestamp))
  }, { merge: true });
};

exports.stopFocusTime = async (userId, timestamp) => {
  const date = new Date(timestamp).toISOString().split("T")[0];
  const docRef = db.collection("focus_logs").doc(`${userId}_${date}`);

  const doc = await docRef.get();
  if (!doc.exists || !doc.data().focusStart) {
    throw new Error("Focus session was not started.");
  }

  const focusStart = doc.data().focusStart.toDate();
  const focusEnd = new Date(timestamp);
  const diffMinutes = Math.round((focusEnd - focusStart) / 60000);

  await docRef.set({
    focusEnd: admin.firestore.Timestamp.fromDate(focusEnd),
    focus_minutes: diffMinutes
  }, { merge: true });
};
