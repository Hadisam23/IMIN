const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');

const router = express.Router();

// Helper: Get joined players for a game
function getJoinedPlayers(gameId) {
  const players = [];
  for (const [key, join] of db.joins) {
    if (join.gameId === gameId) {
      const player = db.players.get(join.playerId);
      if (player) {
        players.push({ ...player, timestamp: join.timestamp });
      }
    }
  }
  return players.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
}

// Helper: Get player count for a game
function getPlayerCount(gameId) {
  let count = 0;
  for (const [key, join] of db.joins) {
    if (join.gameId === gameId) count++;
  }
  return count;
}

// Helper: Update game status based on player count
function updateGameStatus(gameId) {
  const game = db.games.get(gameId);
  if (!game || game.status === 'locked') return;

  const count = getPlayerCount(gameId);
  game.status = count >= game.maxPlayers ? 'full' : 'open';
}

// POST /games - Create a new game
router.post('/', (req, res) => {
  try {
    const { sport, time, location, level, maxPlayers } = req.body;

    if (!sport || !time || !location || !level || !maxPlayers) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const id = uuidv4();
    const game = {
      id,
      sport,
      time,
      location,
      level,
      maxPlayers,
      status: 'open',
      createdAt: new Date().toISOString()
    };

    db.games.set(id, game);

    const baseUrl = process.env.BASE_URL || `http://${req.get('host')}`;
    const joinUrl = `${baseUrl}/join/${id}`;

    res.status(201).json({
      ...game,
      joinUrl,
      players: [],
      playerCount: 0
    });
  } catch (error) {
    console.error('Create game error:', error);
    res.status(500).json({ error: 'Failed to create game' });
  }
});

// GET /games - List all games
router.get('/', (req, res) => {
  try {
    const now = new Date();
    const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000);

    const games = [];
    for (const [id, game] of db.games) {
      const gameTime = new Date(game.time);
      if (gameTime >= twoHoursAgo) {
        games.push({
          ...game,
          playerCount: getPlayerCount(game.id),
          players: getJoinedPlayers(game.id)
        });
      }
    }

    games.sort((a, b) => new Date(a.time) - new Date(b.time));
    res.json(games);
  } catch (error) {
    console.error('List games error:', error);
    res.status(500).json({ error: 'Failed to fetch games' });
  }
});

// GET /games/:id - Get game details
router.get('/:id', (req, res) => {
  try {
    const game = db.games.get(req.params.id);

    if (!game) {
      return res.status(404).json({ error: 'Game not found' });
    }

    const players = getJoinedPlayers(game.id);
    const baseUrl = process.env.BASE_URL || `http://${req.get('host')}`;

    res.json({
      ...game,
      joinUrl: `${baseUrl}/join/${game.id}`,
      players,
      playerCount: players.length
    });
  } catch (error) {
    console.error('Get game error:', error);
    res.status(500).json({ error: 'Failed to fetch game' });
  }
});

// POST /games/:id/join - Join a game
router.post('/:id/join', (req, res) => {
  try {
    const { name, phone } = req.body;
    const gameId = req.params.id;

    if (!name || name.trim() === '') {
      return res.status(400).json({ error: 'Name is required' });
    }

    if (!phone || phone.trim() === '') {
      return res.status(400).json({ error: 'Phone number is required' });
    }

    const game = db.games.get(gameId);

    if (!game) {
      return res.status(404).json({ error: 'Game not found' });
    }

    if (game.status === 'locked') {
      return res.status(400).json({ error: 'Game is locked' });
    }

    // Check if phone already exists in this game
    const existingPlayers = getJoinedPlayers(gameId);
    const phoneExists = existingPlayers.some(p => p.phone === phone.trim());
    if (phoneExists) {
      return res.status(400).json({ error: 'This phone number is already registered for this game' });
    }

    const currentCount = getPlayerCount(gameId);

    if (currentCount >= game.maxPlayers) {
      return res.status(400).json({ error: 'Game is full' });
    }

    // Create player
    const playerId = uuidv4();
    const player = {
      id: playerId,
      name: name.trim(),
      phone: phone.trim()
    };
    db.players.set(playerId, player);

    // Join game
    const joinKey = `${gameId}:${playerId}`;
    db.joins.set(joinKey, {
      gameId,
      playerId,
      timestamp: new Date().toISOString()
    });

    // Update game status
    updateGameStatus(gameId);

    const updatedGame = db.games.get(gameId);
    const players = getJoinedPlayers(gameId);
    const baseUrl = process.env.BASE_URL || `http://${req.get('host')}`;

    res.status(201).json({
      success: true,
      message: `You're in! ${players.length}/${updatedGame.maxPlayers} players joined.`,
      game: {
        ...updatedGame,
        joinUrl: `${baseUrl}/join/${gameId}`,
        players,
        playerCount: players.length
      }
    });
  } catch (error) {
    console.error('Join game error:', error);
    res.status(500).json({ error: 'Failed to join game' });
  }
});

// PATCH /games/:id - Update game status
router.patch('/:id', (req, res) => {
  try {
    const { status } = req.body;
    const gameId = req.params.id;

    const game = db.games.get(gameId);

    if (!game) {
      return res.status(404).json({ error: 'Game not found' });
    }

    if (status && ['open', 'full', 'locked', 'cancelled'].includes(status)) {
      game.status = status;
    }

    const players = getJoinedPlayers(gameId);
    const baseUrl = process.env.BASE_URL || `http://${req.get('host')}`;

    res.json({
      ...game,
      joinUrl: `${baseUrl}/join/${gameId}`,
      players,
      playerCount: players.length
    });
  } catch (error) {
    console.error('Update game error:', error);
    res.status(500).json({ error: 'Failed to update game' });
  }
});

// DELETE /games/:id - Delete a game
router.delete('/:id', (req, res) => {
  try {
    const gameId = req.params.id;

    if (!db.games.has(gameId)) {
      return res.status(404).json({ error: 'Game not found' });
    }

    // Delete joins for this game
    for (const [key, join] of db.joins) {
      if (join.gameId === gameId) {
        db.joins.delete(key);
      }
    }

    db.games.delete(gameId);
    res.json({ success: true });
  } catch (error) {
    console.error('Delete game error:', error);
    res.status(500).json({ error: 'Failed to delete game' });
  }
});

module.exports = router;
