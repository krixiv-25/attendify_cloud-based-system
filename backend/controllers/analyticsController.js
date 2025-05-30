const attendanceService = require('../services/attendanceService');
exports.getOverviewAnalytics = async (req, res) => {
const date = req.query.date; // expected format: YYYY-MM-DD
if (!date) return res.status(400).json({ error: 'Missing date param' });
try {
const users = await attendanceService.getAllUsers();
const logs = await attendanceService.getAttendanceForDate(date);
const presentToday = logs.filter(log => !log.absent);
const lateToday = logs.filter(log => log.isLate); // Updated key name
const focusTimes = presentToday.map(log => log.focus_minutes || 0);

const absenteeIds = users
  .map(user => user.id)
  .filter(id => !logs.find(log => log.userId === id));

const absenteeList = users
  .filter(u => absenteeIds.includes(u.id))
  .map(u => u.name);

const departmentStats = {};
for (const user of users) {
  const dept = user.department || 'Unknown';
  if (!departmentStats[dept]) departmentStats[dept] = { present: 0, total: 0 };
  departmentStats[dept].total++;
  const wasPresent = logs.find(log => log.userId === user.id && !log.absent);
  if (wasPresent) departmentStats[dept].present++;
}

const avgFocus = focusTimes.length
  ? Math.round(focusTimes.reduce((a, b) => a + b, 0) / focusTimes.length)
  : 0;
const hours = Math.floor(avgFocus / 60);
const mins = avgFocus % 60;

res.json({
  totalEmployees: users.length,
  presentToday: presentToday.length,
  lateToday: lateToday.length,
  averageFocusTime: `${hours}h ${mins}m`,
  absenteeList,
  departmentStats
});

} catch (err) {
console.error(err);
res.status(500).json({ error: 'Failed to fetch analytics' });
}
};
