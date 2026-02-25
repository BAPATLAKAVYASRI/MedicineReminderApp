const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const { normalizePhone } = require('../services/phoneUtil');

// Log activity helper
async function logActivity(userId, action, details = {}) {
  try {
    await db.query(
      'INSERT INTO activity_logs (user_id, action, details) VALUES (?, ?, ?)',
      [userId, action, JSON.stringify(details)]
    );
  } catch (error) {
    console.error('Failed to log activity:', error);
  }
}

// Register new user
exports.register = async (req, res) => {
  try {
    let { name, username, phone, email, password } = req.body;

    // Normalize inputs
    if (typeof email === 'string') email = email.trim().toLowerCase();
    if (typeof name === 'string') name = name.trim();
    if (typeof username === 'string') username = username.trim();
    if (typeof phone === 'string') phone = phone.trim();

    // Validation
    if (!name || !username || !phone || !email || !password) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    // Normalize phone to E.164
    const defaultCountry = process.env.DEFAULT_COUNTRY_CODE || '+91';
    const normalizedPhone = normalizePhone(phone, defaultCountry);
    if (!normalizedPhone) {
      return res.status(400).json({ error: 'Invalid phone number. Use E.164 format like +9198XXXXXXXX.' });
    }

    // Check if email already exists
    const [existingEmail] = await db.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (existingEmail.length > 0) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Check if username already exists
    const [existingUsername] = await db.query(
      'SELECT * FROM users WHERE username = ?',
      [username]
    );

    if (existingUsername.length > 0) {
      return res.status(400).json({ error: 'Username already taken' });
    }

    // Check if phone already exists (normalized)
    const [existingPhone] = await db.query(
      'SELECT * FROM users WHERE phone = ?',
      [normalizedPhone]
    );

    if (existingPhone.length > 0) {
      return res.status(400).json({ error: 'Phone number already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const [result] = await db.query(
      'INSERT INTO users (name, username, phone, email, password) VALUES (?, ?, ?, ?, ?)',
      [name, username, normalizedPhone, email, hashedPassword]
    );

    const token = jwt.sign(
      { userId: result.insertId },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    // Log registration
    await logActivity(result.insertId, 'REGISTER', { email, username });

    res.status(201).json({
      message: 'Registration successful',
      token,
      user: {
        id: result.insertId,
        name,
        username,
        phone: normalizedPhone,
        email
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
};

// Login user
exports.login = async (req, res) => {
  try {
    let { identifier, email, password } = req.body;

    // Backward compatibility: accept 'email' param as identifier
    identifier = typeof identifier === 'string' && identifier.trim() !== ''
      ? identifier
      : email;

    if (!identifier || !password) {
      return res.status(400).json({ error: 'Identifier and password are required' });
    }

    identifier = String(identifier).trim();

    // Determine type
    const looksLikeEmail = identifier.includes('@');
    const digitsOnly = identifier.replace(/\D/g, '');

    const normalizedEmail = looksLikeEmail ? identifier.toLowerCase() : '__none__';
    const normalizedPhone = digitsOnly.length >= 7 ? digitsOnly : '__none__';
    const normalizedUsername = identifier; // keep as-is; DB collation usually case-insensitive

    const [users] = await db.query(
      'SELECT * FROM users WHERE email = ? OR username = ? OR REPLACE(phone, " ", "") = ? LIMIT 1',
      [normalizedEmail, normalizedUsername, normalizedPhone]
    );

    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = users[0];
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    // Log login
    await logActivity(user.id, 'LOGIN', { identifier });

    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        username: user.username,
        phone: user.phone,
        email: user.email
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
};

// Logout user
exports.logout = async (req, res) => {
  try {
    const userId = req.userId; // From auth middleware

    // Log logout
    await logActivity(userId, 'LOGOUT', {});

    res.status(200).json({
      message: 'Logout successful'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Logout failed' });
  }
};

// Forgot password
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const [users] = await db.query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Log password reset request
    await logActivity(users[0].id, 'PASSWORD_RESET_REQUEST', { email });

    res.status(200).json({
      message: `Password reset link sent to ${email}`
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: 'Failed to process request' });
  }
};