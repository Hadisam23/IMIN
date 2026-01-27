// Simple in-memory database for MVP
const db = {
  games: new Map(),
  players: new Map(),
  joins: new Map() // key: `${gameId}:${playerId}`
};

module.exports = db;
