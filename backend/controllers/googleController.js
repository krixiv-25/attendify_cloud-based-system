const { google } = require('googleapis');
const { saveUserTokens, getUserTokens } = require('../services/firebaseServices');

const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  process.env.GOOGLE_REDIRECT_URI
);

exports.getGoogleAuthURL = (req, res) => {
  const url = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/calendar.readonly',
    ],
    prompt: 'consent'
  });
  res.redirect(url);
};

exports.googleCallback = async (req, res) => {
  const { tokens } = await oauth2Client.getToken(req.query.code);
  oauth2Client.setCredentials(tokens);

  const oauth2 = google.oauth2({ version: 'v2', auth: oauth2Client });
  const { data: userInfo } = await oauth2.userinfo.get();

  await saveUserTokens(userInfo.id, 'google', userInfo.email, tokens);
  res.send(`Google account linked for ${userInfo.email}`);
};

exports.fetchTodayEvents = async (req, res) => {
  const userId = req.query.user;
  const tokens = await getUserTokens(userId);
  if (!tokens) return res.status(404).send('Google tokens not found');

  oauth2Client.setCredentials(tokens);
  const calendar = google.calendar({ version: 'v3', auth: oauth2Client });

  const now = new Date();
  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  const result = await calendar.events.list({
    calendarId: 'primary',
    timeMin: now.toISOString(),
    timeMax: endOfDay.toISOString(),
    singleEvents: true,
    orderBy: 'startTime'
  });

  const events = result.data.items.map(event => ({
    summary: event.summary,
    meetLink: event.hangoutLink || '',
    start: event.start.dateTime || event.start.date,
    end: event.end.dateTime || event.end.date,
  }));

  res.json(events);
};
