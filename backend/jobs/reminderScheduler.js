const cron = require('node-cron');
const db = require('../config/database');
const { sendSMS } = require('../services/smsService');
const { placeCall } = require('../services/voiceService');

function nowHHmm() {
  const d = new Date();
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  return `${hh}:${mm}`;
}

async function fetchDueReminders(hhmm) {
  const [rows] = await db.query(
    `SELECT m.id AS medicine_id, m.user_id, m.name AS medicine_name, m.dosage, m.frequency, m.times,
            u.phone AS user_phone, u.name AS user_name
     FROM medicines m
     JOIN users u ON u.id = m.user_id`
  );

  const due = [];
  for (const row of rows) {
    let times = [];
    try {
      if (typeof row.times === 'string') times = JSON.parse(row.times);
      else if (Array.isArray(row.times)) times = row.times;
    } catch (_) { times = []; }

    if (Array.isArray(times) && times.includes(hhmm)) {
      due.push(row);
    }
  }
  return due;
}

async function processDue(hhmm) {
  const due = await fetchDueReminders(hhmm);
  for (const item of due) {
    const to = item.user_phone;
    if (!to) {
      console.warn(`User ${item.user_id} has no phone number; skipping reminder`);
      continue;
    }
    const body = `Hi ${item.user_name || ''}, it's ${hhmm}. Time to take your medicine: ${item.medicine_name} (${item.dosage}).`;
    try {
      await sendSMS(to, body.trim());
      console.log(`Sent reminder to ${to} for medicine ${item.medicine_name} at ${hhmm}`);
    } catch (err) {
      console.error(`Failed to send SMS reminder to ${to}:`, err.message);
      // Voice fallback
      try {
        const voiceMsg = `Hello ${item.user_name || ''}. It is ${hhmm}. This is your Medi Remind. Please take your medicine: ${item.medicine_name}, ${item.dosage}.`;
        await placeCall(to, voiceMsg.trim());
        console.log(`Placed voice call reminder to ${to} for medicine ${item.medicine_name} at ${hhmm}`);
      } catch (callErr) {
        console.error(`Failed to place voice call to ${to}:`, callErr.message);
      }
    }
  }
}

function startScheduler() {
  console.log('⏰ Reminder scheduler initialized (every minute).');
  cron.schedule('* * * * *', async () => {
    const hhmm = nowHHmm();
    try {
      await processDue(hhmm);
    } catch (e) {
      console.error('Scheduler tick error:', e.message);
    }
  });
}

startScheduler();

module.exports = { startScheduler };
