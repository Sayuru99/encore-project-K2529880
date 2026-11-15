const express = require('express');
const crypto = require('node:crypto');
const { DatabaseSync } = require('node:sqlite');
const path = require('node:path');

// shortcut: listings in a JSON file, swap for a real ticketing feed when one has a public API
const SHOWS = require('./shows.json');
const { seed } = require('./seed');

const TYPES = ['concert', 'theatre', 'comedy', 'festival', 'sport', 'other'];
const STATUSES = ['planned', 'attended'];

function createApp(dbPath = process.env.DB_PATH || 'encore.db', { demo = false } = {}) {
  const db = new DatabaseSync(dbPath);
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT UNIQUE NOT NULL,
      salt TEXT NOT NULL, hash TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS sessions (token TEXT PRIMARY KEY, user_id TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS events (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL, title TEXT NOT NULL, artist TEXT,
      venue TEXT, date TEXT NOT NULL, type TEXT NOT NULL, status TEXT NOT NULL,
      price REAL NOT NULL DEFAULT 0, rating INTEGER NOT NULL DEFAULT 0, notes TEXT,
      image TEXT, updated_at TEXT NOT NULL);
  `);

  const hash = (password, salt) => crypto.scryptSync(password, salt, 64).toString('hex');
  if (demo) seed(db, hash, SHOWS);
  const publicUser = (u) => ({ id: u.id, name: u.name, email: u.email });
  const newSession = (userId) => {
    const token = crypto.randomBytes(32).toString('hex');
    db.prepare('INSERT INTO sessions VALUES (?, ?)').run(token, userId);
    return token;
  };
  const toJson = (r) => ({
    id: r.id, title: r.title, artist: r.artist, venue: r.venue, date: r.date,
    type: r.type, status: r.status, price: r.price, rating: r.rating,
    notes: r.notes, image: r.image || '', updatedAt: r.updated_at,
  });

  function validateEvent(b) {
    const errors = [];
    if (typeof b.title !== 'string' || !b.title.trim() || b.title.length > 100) errors.push('title is required (max 100 chars)');
    if (!b.date || isNaN(Date.parse(b.date))) errors.push('date must be a valid ISO date');
    if (!TYPES.includes(b.type)) errors.push(`type must be one of ${TYPES.join(', ')}`);
    if (!STATUSES.includes(b.status)) errors.push(`status must be one of ${STATUSES.join(', ')}`);
    if (typeof b.price !== 'number' || b.price < 0) errors.push('price must be a number >= 0');
    if (!Number.isInteger(b.rating) || b.rating < 0 || b.rating > 5) errors.push('rating must be 0 to 5');
    if (!b.updatedAt || isNaN(Date.parse(b.updatedAt))) errors.push('updatedAt must be a valid ISO date');
    return errors;
  }

  const app = express();
  app.use(express.json());

  app.use('/images', express.static(path.join(__dirname, 'public/images'), { maxAge: '7d' }));
  app.get('/health', (req, res) => res.json({ ok: true }));

  // public listings for the Discover tab, from 1 January this year, optional ?type=concert
  app.get('/shows', (req, res) => {
    const { type } = req.query;
    const from = new Date(new Date().getFullYear(), 0, 1).getTime();
    res.json(SHOWS.filter((s) => (!type || s.type === type) && Date.parse(s.date) >= from)
      .sort((a, b) => Date.parse(a.date) - Date.parse(b.date)));
  });

  app.post('/auth/register', (req, res) => {
    const { name, email, password } = req.body || {};
    if (!name?.trim() || !/^\S+@\S+\.\S+$/.test(email || '') || (password || '').length < 6) {
      return res.status(400).json({ error: 'name, valid email and a 6+ character password are required' });
    }
    const mail = email.toLowerCase();
    if (db.prepare('SELECT 1 FROM users WHERE email = ?').get(mail)) {
      return res.status(409).json({ error: 'an account with this email already exists' });
    }
    const user = { id: crypto.randomUUID(), name: name.trim(), email: mail };
    const salt = crypto.randomBytes(16).toString('hex');
    db.prepare('INSERT INTO users VALUES (?, ?, ?, ?, ?)').run(user.id, user.name, mail, salt, hash(password, salt));
    res.status(201).json({ token: newSession(user.id), user });
  });

  app.post('/auth/login', (req, res) => {
    const { email, password } = req.body || {};
    const u = db.prepare('SELECT * FROM users WHERE email = ?').get((email || '').toLowerCase());
    const ok = u && crypto.timingSafeEqual(Buffer.from(u.hash, 'hex'), Buffer.from(hash(password || '', u.salt), 'hex'));
    if (!ok) return res.status(401).json({ error: 'wrong email or password' });
    res.json({ token: newSession(u.id), user: publicUser(u) });
  });

  // everything below needs a valid Bearer token
  app.use((req, res, next) => {
    const token = (req.headers.authorization || '').replace(/^Bearer /, '');
    const s = db.prepare('SELECT user_id FROM sessions WHERE token = ?').get(token);
    if (!s) return res.status(401).json({ error: 'not signed in' });
    req.userId = s.user_id;
    req.token = token;
    next();
  });

  app.post('/auth/logout', (req, res) => {
    db.prepare('DELETE FROM sessions WHERE token = ?').run(req.token);
    res.status(204).end();
  });

  app.get('/me', (req, res) => {
    res.json(publicUser(db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId)));
  });

  app.put('/me', (req, res) => {
    const name = (req.body?.name || '').trim();
    if (!name || name.length > 50) return res.status(400).json({ error: 'name is required (max 50 chars)' });
    db.prepare('UPDATE users SET name = ? WHERE id = ?').run(name, req.userId);
    res.json(publicUser(db.prepare('SELECT * FROM users WHERE id = ?').get(req.userId)));
  });

  const findEvent = (id, userId) => db.prepare('SELECT * FROM events WHERE id = ? AND user_id = ?').get(id, userId);

  app.get('/events', (req, res) => {
    res.json(db.prepare('SELECT * FROM events WHERE user_id = ? ORDER BY date DESC').all(req.userId).map(toJson));
  });

  app.get('/events/:id', (req, res) => {
    const e = findEvent(req.params.id, req.userId);
    e ? res.json(toJson(e)) : res.status(404).json({ error: 'event not found' });
  });

  // the client makes the id so an offline create can be retried safely
  app.post('/events', (req, res) => {
    const b = req.body || {};
    const errors = validateEvent(b);
    if (typeof b.id !== 'string' || !b.id) errors.push('id is required');
    if (errors.length) return res.status(400).json({ error: errors.join('; ') });
    const existing = db.prepare('SELECT * FROM events WHERE id = ?').get(b.id);
    if (existing) {
      if (existing.user_id !== req.userId) return res.status(409).json({ error: 'id already used' });
      return res.status(200).json(toJson(existing));
    }
    db.prepare(`INSERT INTO events VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`).run(
      b.id, req.userId, b.title.trim(), b.artist || '', b.venue || '', b.date, b.type, b.status,
      b.price, b.rating, b.notes || '', b.image || '', b.updatedAt);
    res.status(201).json(toJson(findEvent(b.id, req.userId)));
  });

  app.put('/events/:id', (req, res) => {
    const b = req.body || {};
    const errors = validateEvent(b);
    if (errors.length) return res.status(400).json({ error: errors.join('; ') });
    const e = findEvent(req.params.id, req.userId);
    if (!e) return res.status(404).json({ error: 'event not found' });
    // last write wins: an older offline edit must not overwrite a newer one
    if (Date.parse(b.updatedAt) < Date.parse(e.updated_at)) {
      return res.status(409).json({ error: 'a newer version exists on the server', server: toJson(e) });
    }
    db.prepare(`UPDATE events SET title=?, artist=?, venue=?, date=?, type=?, status=?, price=?,
      rating=?, notes=?, image=?, updated_at=? WHERE id=? AND user_id=?`).run(
      b.title.trim(), b.artist || '', b.venue || '', b.date, b.type, b.status, b.price, b.rating,
      b.notes || '', b.image || '', b.updatedAt, req.params.id, req.userId);
    res.json(toJson(findEvent(req.params.id, req.userId)));
  });

  // deleting something already gone is still success, so offline deletes can be retried
  app.delete('/events/:id', (req, res) => {
    db.prepare('DELETE FROM events WHERE id = ? AND user_id = ?').run(req.params.id, req.userId);
    res.status(204).end();
  });

  app.use((err, req, res, next) => {
    if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'invalid JSON' });
    console.error(err);
    res.status(500).json({ error: 'server error' });
  });

  return app;
}

if (require.main === module) {
  const port = process.env.PORT || 3000;
  createApp(undefined, { demo: process.env.DEMO_DATA !== 'off' }).listen(port, () => console.log(`Encore API on port ${port}`));
}

module.exports = { createApp };
