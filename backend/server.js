const express = require('express');
const cors = require('cors');
const path = require('path');
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
