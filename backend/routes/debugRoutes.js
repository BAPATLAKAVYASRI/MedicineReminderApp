const express = require('express');
const router = express.Router();
const { sendSMS } = require('../services/smsService');
const { placeCall } = require('../services/voiceService');

// TEMPORARY: Direct SMS test endpoint
// POST /api/debug/send-sms
// Body: { "to": "+91XXXXXXXXXX", "body": "Hello" }
router.post('/send-sms', async (req, res) => {
  try {
    const { to, body } = req.body || {};
    if (!to || !body) {
      return res.status(400).json({ error: 'to and body are required' });
    }

    const result = await sendSMS(to, body);
    return res.status(200).json({ message: 'SMS attempted', result });
  } catch (err) {
    console.error('Debug send-sms error:', err.message);
    return res.status(500).json({ error: 'Failed to send SMS', details: err.message });
  }
});

// TEMPORARY: Direct Voice Call test endpoint
// POST /api/debug/call
// Body: { "to": "+91XXXXXXXXXX", "message": "Hello" }
router.post('/call', async (req, res) => {
  try {
    const { to, message } = req.body || {};
    if (!to || !message) {
      return res.status(400).json({ error: 'to and message are required' });
    }

    const result = await placeCall(to, message);
    return res.status(200).json({ message: 'Call attempted', result });
  } catch (err) {
    console.error('Debug call error:', err.message);
    return res.status(500).json({ error: 'Failed to place call', details: err.message });
  }
});

module.exports = router;
