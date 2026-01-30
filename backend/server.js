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
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Seed database from backup if empty
function seedFromBackup() {
  const count = db.prepare('SELECT COUNT(*) as count FROM games').get().count;
  if (count > 0) return;

  const backupPath = path.join(__dirname, '..', 'data-backup-full.json');
  if (!fs.existsSync(backupPath)) {
    console.log('No backup file found, starting with empty database');
    return;
  }

  console.log('Seeding database from backup...');
  const data = JSON.parse(fs.readFileSync(backupPath, 'utf8'));

  const insertGame = db.prepare(`INSERT OR IGNORE INTO games (id, sport, time, location, level, maxPlayers, isPublic, creatorPhone, status, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`);
  const insertPlayer = db.prepare(`INSERT OR IGNORE INTO players (id, name, phone) VALUES (?, ?, ?)`);
  const insertJoin = db.prepare(`INSERT OR IGNORE INTO joins (gameId, playerId, timestamp, skillLevel) VALUES (?, ?, ?, ?)`);

  const seed = db.transaction(() => {
    for (const game of data.games) {
      insertGame.run(game.id, game.sport, game.time, game.location, game.level, game.maxPlayers, game.isPublic ? 1 : 0, game.creatorPhone || null, game.status, game.createdAt);

      if (game.players) {
        for (const player of game.players) {
          insertPlayer.run(player.id, player.name, player.phone || null);
          insertJoin.run(game.id, player.id, player.timestamp, player.skillLevel || null);
        }
      }
    }
  });

  seed();
  const seeded = db.prepare('SELECT COUNT(*) as count FROM games').get().count;
  console.log(`Seeded ${seeded} games from backup`);
}

seedFromBackup();

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
