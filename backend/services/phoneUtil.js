function onlyDigits(s) {
  return (s || '').replace(/\D+/g, '');
}

function normalizePhone(input, defaultCountry = '+91') {
  if (!input || typeof input !== 'string') return null;
  const trimmed = input.trim();
  if (trimmed.startsWith('+')) {
    const digits = '+' + onlyDigits(trimmed);
    if (digits.length >= 8 && digits.length <= 16) return digits;
    return null;
  }
  const digits = onlyDigits(trimmed);
  if (digits.length === 10 && defaultCountry === '+91') return defaultCountry + digits;
  if (digits.length >= 8 && digits.length <= 15) return '+' + digits;
  return null;
}

module.exports = { normalizePhone };
