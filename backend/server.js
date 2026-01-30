const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const db = require('./db');
const gamesRouter = require('./routes/games');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// API Routes
app.use('/games', gamesRouter);

// Serve join page for /join/:gameId
app.get('/join/:gameId', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'join.html'));
});

// Health check
app.get('/health', (req, res) => {
  const gameCount = db.prepare('SELECT COUNT(*) as count FROM games').get().count;
  const dbPathEnv = process.env.DB_PATH;
  const dbPathUsed = dbPathEnv || path.join(__dirname, 'data.db');
  res.json({ status: 'ok', timestamp: new Date().toISOString(), games: gameCount, dbPathEnv: dbPathEnv || null, dbPathUsed });
});

// Seed endpoint - POST /seed to populate DB with test data
app.post('/seed', (req, res) => {
  try {
    const gameCount = db.prepare('SELECT COUNT(*) as count FROM games').get().count;

    const seedData = {
      games: [
        {
          id: '61daff95-ef09-47a1-94ec-36b455f61000',
          sport: 'Football', time: '2026-02-02T17:00:00Z', location: 'וינטר',
          level: 'Intermediate', maxPlayers: 15, isPublic: true,
          creatorPhone: '0527431379', status: 'open', createdAt: '2026-01-28T11:18:22.795Z',
          players: [
            { id: '19495cd8-2cde-4346-94f5-8b90beb2ecc6', name: 'Hadi samara', phone: '0527431379', timestamp: '2026-01-28T11:18:23.155Z', skillLevel: 3 },
            { id: '19cf5e94-c33a-436f-b104-5ae8f2d9b855', name: 'Shamno hi', phone: '2880856985', timestamp: '2026-01-28T17:09:16.064Z', skillLevel: 4 },
            { id: '801d2ed8-c731-46ca-88e0-7befd7ed6670', name: 'Riko lewis', phone: '2550856982', timestamp: '2026-01-28T17:09:37.522Z', skillLevel: 2 },
          ]
        },
        {
          id: '4bdd6be6-dd18-4024-be76-b81eb0a23e9e',
          sport: 'Football', time: '2026-02-02T17:24:00Z', location: 'וינטר, רמת גן',
          level: 'Intermediate', maxPlayers: 15, isPublic: false,
          creatorPhone: '0527431379', status: 'open', createdAt: '2026-01-29T10:24:22.218Z',
          players: [
            { id: '09debf4c-b268-4a94-aaad-b753d97abdd1', name: 'Hadi samara', phone: '0527431379', timestamp: '2026-01-29T10:24:22.649Z', skillLevel: null },
            { id: 'b6db556c-2b48-4280-bb76-329b53ecfc2d', name: 'Ohad', phone: '0525649838', timestamp: '2026-01-29T11:36:45.308Z', skillLevel: 4 },
            { id: '15a86e0e-0e34-43cb-9cca-49bd398e32da', name: 'Ianiv', phone: '0544853377', timestamp: '2026-01-29T11:42:35.107Z', skillLevel: null },
            { id: '27fd5ef7-4b1c-4d3e-b0c2-b4db94ecabcd', name: 'Dan', phone: '0548040634', timestamp: '2026-01-29T11:51:57.219Z', skillLevel: null },
            { id: '1bde1b2a-e99f-4ce6-8c49-0ec24e3aabcd', name: 'Alon', phone: '0523033325', timestamp: '2026-01-29T11:53:18.965Z', skillLevel: null },
            { id: '6997ab73-a482-4785-8983-fb4d7c2b553a', name: 'Roy Azikri', phone: '0506996445', timestamp: '2026-01-29T11:59:49.453Z', skillLevel: null },
            { id: 'cb15c18d-5fb3-4640-844d-9fb7da9dc00b', name: 'Erlich', phone: '0546210987', timestamp: '2026-01-29T12:22:39.545Z', skillLevel: null },
            { id: '83c0d316-ce65-4a0b-ba4a-0257e2cd6c44', name: 'Iftah', phone: '0547916395', timestamp: '2026-01-29T12:45:21.757Z', skillLevel: null },
            { id: '535188ee-6afe-4ad0-b2ed-7f092047b61e', name: 'Or Shpringer', phone: '0544229792', timestamp: '2026-01-29T15:27:06.255Z', skillLevel: null },
            { id: '18c6c59f-1c59-4a93-b91a-1a844ddfe5b7', name: 'Gena', phone: '0543314200', timestamp: '2026-01-29T20:54:21.652Z', skillLevel: null },
            { id: '3d2dc1c5-1791-43cb-8ad6-550af6eb98da', name: 'Avinoam', phone: '0504522002', timestamp: '2026-01-30T06:53:10.781Z', skillLevel: null },
            { id: '2503ca62-7ebd-47cf-95a5-683e087ca9ac', name: 'Ayal mustafa', phone: '0522553134', timestamp: '2026-01-30T10:42:43.431Z', skillLevel: null },
          ]
        }
      ]
    };

    const insertGame = db.prepare(`INSERT OR IGNORE INTO games (id, sport, time, location, level, maxPlayers, isPublic, creatorPhone, status, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`);
    const insertPlayer = db.prepare(`INSERT OR IGNORE INTO players (id, name, phone) VALUES (?, ?, ?)`);
    const insertJoin = db.prepare(`INSERT OR IGNORE INTO joins (gameId, playerId, timestamp, skillLevel) VALUES (?, ?, ?, ?)`);

    const seedTx = db.transaction(() => {
      for (const game of seedData.games) {
        insertGame.run(game.id, game.sport, game.time, game.location, game.level, game.maxPlayers, game.isPublic ? 1 : 0, game.creatorPhone || null, game.status, game.createdAt);
        if (game.players) {
          for (const player of game.players) {
            insertPlayer.run(player.id, player.name, player.phone || null);
            insertJoin.run(game.id, player.id, player.timestamp, player.skillLevel || null);
          }
        }
      }
    });

    seedTx();
    const newCount = db.prepare('SELECT COUNT(*) as count FROM games').get().count;
    console.log(`Seed complete: ${gameCount} -> ${newCount} games`);
    res.json({ success: true, gamesBefore: gameCount, gamesAfter: newCount });
  } catch (error) {
    console.error('Seed error:', error);
    res.status(500).json({ error: 'Seed failed', details: error.message });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`
🏀 Sports Coordinator Backend
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Server running on port ${PORT}

API Endpoints:
  POST   /games              - Create a game
  GET    /games              - List all games
  GET    /games/:id          - Get game details
  POST   /games/:id/join     - Join a game
  PATCH  /games/:id          - Update game status
  DELETE /games/:id          - Delete a game

Web Join Page:
  GET    /join/:gameId       - Player join page
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  `);
});
