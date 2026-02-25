const dotenv = require('dotenv');

dotenv.config();

let twilioClient = null;

function getClient() {
  if (twilioClient) return twilioClient;
  const { TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN } = process.env;
  if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN) {
    console.warn('Twilio credentials are not set. Voice calling is disabled.');
    return null;
  }
  // Lazy require
  // eslint-disable-next-line global-require
  const twilio = require('twilio');
  twilioClient = twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);
  return twilioClient;
}

async function placeCall(to, message) {
  const client = getClient();
  if (!client) {
    console.log(`[VOICE DRY-RUN] To: ${to} | ${message}`);
    return { dryRun: true };
  }
  const from = process.env.TWILIO_FROM_NUMBER;
  if (!from) {
    console.warn('TWILIO_FROM_NUMBER is not set. Voice calling is disabled.');
    console.log(`[VOICE DRY-RUN] To: ${to} | ${message}`);
    return { dryRun: true };
  }

  const twiml = `<Response><Say>${message}</Say></Response>`;
  try {
    const call = await client.calls.create({
      to,
      from,
      twiml,
    });
    return { sid: call.sid };
  } catch (err) {
    console.error('Failed to place voice call:', err.message);
    throw err;
  }
}

module.exports = { placeCall };
