// ============================================================
// NATION BUILDER - Improved Backend Server
// ============================================================

const express = require('express');
const mysql   = require('mysql2/promise');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const cors    = require('cors');

const app  = express();
const PORT = 3000;

// ⚠️ Production me .env use karo
const JWT_SECRET = 'nation_builder_secret_key_2024';

app.use(cors());
app.use(express.json());

// ============================================================
// MYSQL CONNECTION POOL
// ============================================================
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'admin@123',
  database: 'nation_builder',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// DB Test
(async () => {
  try {
    const conn = await pool.getConnection();
    console.log('✅ MySQL connected successfully!');
    conn.release();
  } catch (err) {
    console.error('❌ MySQL connection failed:', err.message);
    process.exit(1);
  }
})();

// ============================================================
// AUTH MIDDLEWARE
// ============================================================
function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// ============================================================
// ROUTES
// ============================================================

// Health
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Nation Builder API running 🚀' });
});

// ============================================================
// REGISTER
// ============================================================
app.post('/api/register', async (req, res) => {
  const { name, email, phone, state, password } = req.body;

  if (!name || !email || !phone || !state || !password) {
    return res.status(400).json({ msg: 'All fields required' });
  }

  let conn;
  try {
    conn = await pool.getConnection();

    const [existing] = await conn.query(
      'SELECT uid FROM users WHERE email = ?',
      [email.toLowerCase()]
    );

    if (existing.length > 0) {
      return res.status(409).json({ msg: 'Email already exists' });
    }

    const uid      = 'u_' + Date.now();
    const hashPass = await bcrypt.hash(password, 10);

    await conn.query(
      `INSERT INTO users 
      (uid, name, email, phone, state, pass_hash, xp, streak, joined_at) 
      VALUES (?, ?, ?, ?, ?, ?, 50, 1, NOW())`,
      [uid, name, email.toLowerCase(), phone, state, hashPass]
    );

    await conn.query(
      'INSERT IGNORE INTO user_badges (uid, badge_id) VALUES (?, ?)',
      [uid, 'beginner']
    );

    const token = jwt.sign({ uid, name, email }, JWT_SECRET, { expiresIn: '30d' });

    const user = await getUserData(conn, uid);

    res.json({ success: true, token, user });

  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: 'Registration failed' });
  } finally {
    if (conn) conn.release();
  }
});

// ============================================================
// LOGIN
// ============================================================
app.post('/api/login', async (req, res) => {
  const { contact, password } = req.body;

  if (!contact || !password) {
    return res.status(400).json({ msg: 'Missing credentials' });
  }

  let conn;
  try {
    conn = await pool.getConnection();

    const isEmail = contact.includes('@');
    const field   = isEmail ? 'email' : 'phone';

    const [rows] = await conn.query(
      `SELECT * FROM users WHERE ${field} = ?`,
      [contact.toLowerCase()]
    );

    if (rows.length === 0) {
      return res.status(401).json({ msg: 'Invalid credentials' });
    }

    const user = rows[0];

    const match = await bcrypt.compare(password, user.pass_hash);
    if (!match) {
      return res.status(401).json({ msg: 'Invalid credentials' });
    }

    // Update login streak
    const today = new Date().toISOString().slice(0, 10);
    const last  = user.last_login ? user.last_login.toISOString().slice(0, 10) : null;

    if (last !== today) {
      await conn.query(
        'UPDATE users SET streak = streak + 1, last_login = NOW() WHERE uid = ?',
        [user.uid]
      );
    }

    const token = jwt.sign(
      { uid: user.uid, name: user.name, email: user.email },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    const fullUser = await getUserData(conn, user.uid);

    res.json({ success: true, token, user: fullUser });

  } catch (err) {
    console.error(err);
    res.status(500).json({ msg: 'Login failed' });
  } finally {
    if (conn) conn.release();
  }
});

// ============================================================
// PROFILE
// ============================================================
app.get('/api/me', authMiddleware, async (req, res) => {
  let conn;
  try {
    conn = await pool.getConnection();
    const user = await getUserData(conn, req.user.uid);

    if (!user) return res.status(404).json({ msg: 'User not found' });

    res.json({ user });

  } finally {
    if (conn) conn.release();
  }
});

// ============================================================
// XP SYSTEM
// ============================================================
app.post('/api/xp', authMiddleware, async (req, res) => {
  const { amount = 0, reason = '' } = req.body;

  let conn;
  try {
    conn = await pool.getConnection();

    await conn.query(
      'UPDATE users SET xp = xp + ? WHERE uid = ?',
      [amount, req.user.uid]
    );

    await conn.query(
      'INSERT INTO xp_log (uid, amount, reason) VALUES (?, ?, ?)',
      [req.user.uid, amount, reason]
    );

    const [[u]] = await conn.query(
      'SELECT xp FROM users WHERE uid = ?',
      [req.user.uid]
    );

    // Badge unlock
    if (u.xp >= 100) {
      await conn.query(
        'INSERT IGNORE INTO user_badges VALUES (NULL, ?, ?)',
        [req.user.uid, 'aware']
      );
    }

    if (u.xp >= 200) {
      await conn.query(
        'INSERT IGNORE INTO user_badges VALUES (NULL, ?, ?)',
        [req.user.uid, 'nation_builder']
      );
    }

    const user = await getUserData(conn, req.user.uid);

    res.json({ success: true, xp: u.xp, user });

  } finally {
    if (conn) conn.release();
  }
});

// ============================================================
// HELPER
// ============================================================
async function getUserData(conn, uid) {
  const [[user]] = await conn.query(
    'SELECT uid, name, email, phone, state, xp, streak, joined_at FROM users WHERE uid = ?',
    [uid]
  );

  if (!user) return null;

  const [badges] = await conn.query(
    'SELECT badge_id FROM user_badges WHERE uid = ?',
    [uid]
  );

  user.badgesUnlocked = badges.map(b => b.badge_id);

  return user;
}

// ============================================================
// SERVER START
// ============================================================
app.listen(PORT, () => {
  console.log(`🚀 Server running: http://localhost:${PORT}`);
});