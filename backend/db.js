const Database = require('better-sqlite3');
const path = require('path');

const dbPath = process.env.DB_PATH || path.join(__dirname, 'data.db');
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

module.exports = db;
