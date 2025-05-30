const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/googleController');

router.get('/auth', ctrl.getGoogleAuthURL);
router.get('/callback', ctrl.googleCallback);
router.get('/meetings', ctrl.fetchMeetings);

module.exports = router;