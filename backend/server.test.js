const test = require('node:test');
const assert = require('node:assert');
const { createApp } = require('./server');

test('auth, CRUD and conflict handling', async () => {
  const server = createApp(':memory:').listen(0);
  const base = `http://localhost:${server.address().port}`;
  let token;
  const call = async (method, path, body) => {
    const res = await fetch(base + path, {
      method,
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: body && JSON.stringify(body),
    });
    return { status: res.status, body: res.status === 204 ? null : await res.json() };
  };

  try {
    assert.equal((await call('GET', '/events')).status, 401);
    const shows = await call('GET', '/shows?type=concert');
    assert.ok(shows.body.every((s) => s.type === 'concert'));
    assert.equal((await fetch(base + '/images/bmich.jpg')).status, 200);
    assert.equal((await call('POST', '/auth/register', { name: 'A', email: 'bad', password: '123456' })).status, 400);

    const reg = await call('POST', '/auth/register', { name: 'Sam', email: 'sam@test.com', password: 'secret1' });
    assert.equal(reg.status, 201);
    assert.equal((await call('POST', '/auth/register', { name: 'Sam', email: 'SAM@test.com', password: 'secret1' })).status, 409);
    assert.equal((await call('POST', '/auth/login', { email: 'sam@test.com', password: 'wrong' })).status, 401);
    token = (await call('POST', '/auth/login', { email: 'sam@test.com', password: 'secret1' })).body.token;

    const ev = { id: 'e1', title: 'Gig', date: '2026-12-01', type: 'concert', status: 'planned', price: 20, rating: 0, updatedAt: '2026-11-01T10:00:00Z' };
    assert.equal((await call('POST', '/events', { ...ev, rating: 9 })).status, 400);
    assert.equal((await call('POST', '/events', ev)).status, 201);
    assert.equal((await call('POST', '/events', ev)).status, 200, 'retrying a create is safe');
    assert.equal((await call('GET', '/events')).body.length, 1);

    const upd = await call('PUT', '/events/e1', { ...ev, status: 'attended', rating: 5, updatedAt: '2026-11-02T10:00:00Z' });
    assert.equal(upd.body.rating, 5);
    const stale = await call('PUT', '/events/e1', { ...ev, updatedAt: '2026-11-01T11:00:00Z' });
    assert.equal(stale.status, 409);
    assert.equal(stale.body.server.rating, 5);

    assert.equal((await call('DELETE', '/events/e1')).status, 204);
    assert.equal((await call('DELETE', '/events/e1')).status, 204, 'retrying a delete is safe');
    assert.equal((await call('GET', '/events/e1')).status, 404);
  } finally {
    server.close();
  }
});

test('demo accounts are seeded once with diary and plans', async () => {
  const { USERS, PASSWORD } = require('./seed');
  const server = createApp(':memory:', { demo: true }).listen(0);
  const base = `http://localhost:${server.address().port}`;
  try {
    const login = await fetch(base + '/auth/login', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: USERS[0].email, password: PASSWORD }),
    }).then((r) => r.json());
    const events = await fetch(base + '/events', { headers: { Authorization: `Bearer ${login.token}` } }).then((r) => r.json());
    assert.equal(events.length, USERS[0].diary.length + USERS[0].plans.length);
    assert.ok(events.some((e) => e.title === 'Ceylon Music Festival 2026' && e.status === 'attended' && e.rating === 5));
  } finally {
    server.close();
  }
});
