const admin = require('firebase-admin');

// Initialize Firestore if not already done
if (!admin.apps.length) {
  const serviceAccount = require('../config/attendify-firebase-adminsdk.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// Save user OAuth tokens
exports.saveUserTokens = async (userId, provider, email, tokens) => {
  await db.collection('oauth_tokens')
    .doc(userId)
    .set({
      provider,
      email,
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      expires_in: tokens.expires_in,
      timestamp: Date.now(),
    }, { merge: true });
};

// Get user OAuth tokens
exports.getUserTokens = async (userId) => {
  const doc = await db.collection('oauth_tokens').doc(userId).get();
  return doc.exists ? doc.data() : null;
};