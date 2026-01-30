const Database = require('better-sqlite3');
const path = require('path');

const fs = require('fs');

// Use /data volume if it exists (Railway persistent storage), otherwise local
const volumeDir = '/data';
const useVolume = fs.existsSync(volumeDir);
const dbPath = process.env.DB_PATH || (useVolume ? path.join(volumeDir, 'data.db') : path.join(__dirname, 'data.db'));
console.log(`Database path: ${dbPath} (volume: ${useVolume})`);
const db = new Database(dbPath);

// Enable WAL mode for better concurrent read performance
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS games (
    id TEXT PRIMARY KEY,
    sport TEXT NOT NULL,
    time TEXT NOT NULL,
    location TEXT NOT NULL,
    level TEXT NOT NULL,
    maxPlayers INTEGER NOT NULL,
    isPublic INTEGER DEFAULT 0,
    creatorPhone TEXT,
    status TEXT DEFAULT 'open',
    createdAt TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS players (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT
  );

  CREATE TABLE IF NOT EXISTS joins (
    gameId TEXT NOT NULL,
    playerId TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    skillLevel INTEGER,
    PRIMARY KEY (gameId, playerId),
    FOREIGN KEY (gameId) REFERENCES games(id),
    FOREIGN KEY (playerId) REFERENCES players(id)
  );
`);

// Graceful shutdown: checkpoint WAL and close DB
function closeDb() {
  try {
    db.pragma('wal_checkpoint(TRUNCATE)');
    db.close();
    console.log('Database closed cleanly');
  } catch (e) {
    console.error('Error closing database:', e);
  }
}

process.on('SIGTERM', () => { closeDb(); process.exit(0); });
process.on('SIGINT', () => { closeDb(); process.exit(0); });

module.exports = db;
