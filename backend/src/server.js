import bcrypt from 'bcryptjs';
import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import jwt from 'jsonwebtoken';

import { config } from './config.js';
import { pool, query } from './db.js';

const app = express();

app.disable('x-powered-by');
app.set('trust proxy', 1);

app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
  }),
);

app.use(
  cors({
    origin(origin, callback) {
      if (!origin) {
        callback(null, true);
        return;
      }

      if (config.allowedOrigins.includes(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error('Origin not allowed'));
    },
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: false,
  }),
);

app.use(express.json({ limit: '32kb' }));

app.use(
  rateLimit({
    windowMs: 60 * 1000,
    max: 180,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/auth', authLimiter);

function parseLimit(rawValue) {
  if (rawValue === undefined) {
    return 50;
  }

  const value = Number(rawValue);
  if (!Number.isInteger(value) || value < 1 || value > 200) {
    return null;
  }

  return value;
}

function parseAngle(rawValue) {
  const value = Number(rawValue);
  if (!Number.isFinite(value) || value < -180 || value > 180) {
    return null;
  }

  return value;
}

function parseMode(rawValue) {
  if (rawValue === 'level' || rawValue === 'plumb') {
    return rawValue;
  }

  return null;
}

function normalizeEmail(rawValue) {
  if (typeof rawValue !== 'string') {
    return null;
  }

  const value = rawValue.trim().toLowerCase();
  if (value.length < 5 || value.length > 254) {
    return null;
  }

  const isValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  if (!isValid) {
    return null;
  }

  return value;
}

function parsePassword(rawValue) {
  if (typeof rawValue !== 'string') {
    return null;
  }

  if (rawValue.length < 8 || rawValue.length > 72) {
    return null;
  }

  return rawValue;
}

function signToken(userId) {
  return jwt.sign({ sub: userId }, config.jwtSecret, {
    algorithm: 'HS256',
    expiresIn: config.jwtExpiresIn,
  });
}

function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const token = authHeader.slice('Bearer '.length).trim();
  if (!token) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const payload = jwt.verify(token, config.jwtSecret, {
      algorithms: ['HS256'],
    });

    if (
      typeof payload !== 'object' ||
      payload === null ||
      typeof payload.sub !== 'string' ||
      !payload.sub
    ) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    req.auth = { userId: payload.sub };
    next();
  } catch (_error) {
    res.status(401).json({ error: 'Unauthorized' });
  }
}

app.get('/api/health', async (_req, res, next) => {
  try {
    await query('SELECT 1');
    res.status(200).json({ ok: true });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/register', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = parsePassword(req.body?.password);

    if (email === null || password === null) {
      res.status(400).json({ error: 'Invalid payload' });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const result = await query(
      `
      INSERT INTO users (email, password_hash)
      VALUES ($1, $2)
      RETURNING id, email, created_at
      `,
      [email, passwordHash],
    );

    const user = result.rows[0];
    const token = signToken(user.id);

    res.status(201).json({ token, user });
  } catch (error) {
    if (error?.code === '23505') {
      res.status(409).json({ error: 'Account already exists' });
      return;
    }

    next(error);
  }
});

app.post('/api/auth/login', async (req, res, next) => {
  try {
    const email = normalizeEmail(req.body?.email);
    const password = parsePassword(req.body?.password);

    if (email === null || password === null) {
      res.status(400).json({ error: 'Invalid payload' });
      return;
    }

    const result = await query(
      `
      SELECT id, email, password_hash, created_at
      FROM users
      WHERE email = $1
      LIMIT 1
      `,
      [email],
    );

    if (result.rowCount !== 1) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    const user = result.rows[0];
    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    const token = signToken(user.id);

    res.status(200).json({
      token,
      user: {
        id: user.id,
        email: user.email,
        created_at: user.created_at,
      },
    });
  } catch (error) {
    next(error);
  }
});

app.get('/api/me', requireAuth, async (req, res, next) => {
  try {
    const result = await query(
      `
      SELECT id, email, created_at
      FROM users
      WHERE id = $1
      LIMIT 1
      `,
      [req.auth.userId],
    );

    if (result.rowCount !== 1) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    res.status(200).json({ user: result.rows[0] });
  } catch (error) {
    next(error);
  }
});

app.get('/api/measurements', requireAuth, async (req, res, next) => {
  try {
    const limit = parseLimit(req.query.limit);
    if (limit === null) {
      res.status(400).json({ error: 'Invalid limit' });
      return;
    }

    const result = await query(
      `
      SELECT id, angle_x, angle_y, mode, created_at
      FROM measurements
      WHERE user_id = $1
      ORDER BY created_at DESC
      LIMIT $2
      `,
      [req.auth.userId, limit],
    );

    res.status(200).json({ items: result.rows });
  } catch (error) {
    next(error);
  }
});

app.post('/api/measurements', requireAuth, async (req, res, next) => {
  try {
    const angleX = parseAngle(req.body?.angle_x);
    const angleY = parseAngle(req.body?.angle_y);
    const mode = parseMode(req.body?.mode);

    if (angleX === null || angleY === null || mode === null) {
      res.status(400).json({ error: 'Invalid payload' });
      return;
    }

    const result = await query(
      `
      INSERT INTO measurements (user_id, angle_x, angle_y, mode)
      VALUES ($1, $2, $3, $4)
      RETURNING id, angle_x, angle_y, mode, created_at
      `,
      [req.auth.userId, angleX, angleY, mode],
    );

    res.status(201).json({ item: result.rows[0] });
  } catch (error) {
    next(error);
  }
});

app.use((error, _req, res, _next) => {
  const statusCode = error.message === 'Origin not allowed' ? 403 : 500;
  if (statusCode >= 500) {
    console.error(error);
  }

  res.status(statusCode).json({
    error: statusCode === 500 ? 'Internal server error' : error.message,
  });
});

const server = app.listen(config.port, () => {
  console.log(`API started on http://localhost:${config.port}`);
});

async function shutdown() {
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
