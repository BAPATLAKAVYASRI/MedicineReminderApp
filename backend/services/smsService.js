const dotenv = require('dotenv');

dotenv.config();

let twilioClient = null;

function getClient() {
  if (twilioClient) return twilioClient;
  const { TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN } = process.env;
  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN) {
    console.warn('Twilio credentials are not set. SMS sending is disabled.');
    return null;
  }
  // Lazy require so app can run without deps when not configured
  // eslint-disable-next-line global-require
  const twilio = require('twilio');
  twilioClient = twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);
  return twilioClient;
}

async function sendSMS(to, body) {
  try {
    const client = getClient();
    if (!client) {
      console.log(`[SMS DRY-RUN] To: ${to} | ${body}`);
      return { dryRun: true };
    }

    const from = process.env.TWILIO_FROM_NUMBER;
    if (!from) {
      console.warn('TWILIO_FROM_NUMBER is not set. SMS sending is disabled.');
      console.log(`[SMS DRY-RUN] To: ${to} | ${body}`);
      return { dryRun: true };
    }

    const msg = await client.messages.create({ from, to, body });
    return { sid: msg.sid };
  } catch (err) {
    console.error('Failed to send SMS:', err.message);
    throw err;
  }
}

module.exports = { sendSMS };
