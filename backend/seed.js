const crypto = require('node:crypto');

// Demo accounts for the presentation. The free host wipes SQLite on restart, so these come back every boot.
const PASSWORD = 'encore2026';
const USERS = [
  {
    name: 'Sayuru', email: 'sayuru@encore.lk',
    diary: [
      ['real-01', 5, 'Packed stands for the first home game. Went with the uni gang, got soaked in the second half and nobody cared.'],
      ['real-02', 4, 'Expensive but worth it once. His crowd work was the best part.'],
      ['real-04', 4, 'Stayed for two of the three days. Sunset sets on the beach were the best part. Long queue for the shuttle back.'],
      ['real-05', 5, 'Mohombi was unreal live, Bumpy Ride had the whole of Port City jumping. BNS closing set was a great touch.'],
      ['real-06', 5, 'DJ Snake finally in Colombo. Turn Down for What drop was the loudest crowd I have ever heard.'],
      ['real-07', 3, 'Dancing was spot on, but the sound was a bit muddy where we sat at the back.'],
    ],
    plans: ['show-04', 'show-01', 'show-03'],
  },
  {
    name: 'Nethmi Perera', email: 'nethmi@encore.lk',
    diary: [
      ['real-03', 5, "Sanka Dineth's arrangements sounded even better live."],
      ['real-05', 4, 'Great line-up, but parking was a nightmare. Take a tuk.'],
    ],
    plans: ['show-06', 'show-10'],
  },
  {
    name: 'Kavindu Silva', email: 'kavindu@encore.lk',
    diary: [
      ['real-01', 4, 'Good game, poor view from the C stand.'],
      ['real-06', 5, 'Both nights. Day two was better.'],
    ],
    plans: ['show-03', 'show-05', 'show-07'],
  },
  {
    name: 'Dilini Fernando', email: 'dilini@encore.lk',
    diary: [
      ['real-02', 5, 'Laughed until my face hurt.'],
      ['real-07', 4, 'Took my parents. Amma knew every song.'],
    ],
    plans: ['show-02', 'show-08'],
  },
];

function seed(db, hash, shows) {
  const byId = Object.fromEntries(shows.map((s) => [s.id, s]));
  const insert = db.prepare('INSERT OR IGNORE INTO events VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  db.exec('BEGIN'); // one commit instead of one per row keeps boot fast on a real disk
  for (const u of USERS) {
    if (db.prepare('SELECT 1 FROM users WHERE email = ?').get(u.email)) continue;
    const id = crypto.randomUUID();
    const salt = crypto.randomBytes(16).toString('hex');
    db.prepare('INSERT INTO users VALUES (?, ?, ?, ?, ?)').run(id, u.name, u.email, salt, hash(PASSWORD, salt));
    const add = (showId, status, rating, notes) => {
      const s = byId[showId];
      insert.run(crypto.randomUUID(), id, s.title, s.artist, s.venue, s.date, s.type, status, s.price, rating, notes, s.image,
        new Date().toISOString());
    };
    for (const [showId, rating, notes] of u.diary) add(showId, 'attended', rating, notes);
    for (const showId of u.plans) add(showId, 'planned', 0, '');
  }
  db.exec('COMMIT');
}

module.exports = { seed, USERS, PASSWORD };
