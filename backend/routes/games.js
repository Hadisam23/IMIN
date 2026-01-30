const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');

const router = express.Router();

// Prepared statements
const stmts = {
  insertGame: db.prepare(`INSERT INTO games (id, sport, time, location, level, maxPlayers, isPublic, creatorPhone, status, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`),
  getGame: db.prepare(`SELECT * FROM games WHERE id = ?`),
  updateGameStatus: db.prepare(`UPDATE games SET status = ? WHERE id = ?`),
  updateGameVisibility: db.prepare(`UPDATE games SET isPublic = ? WHERE id = ?`),
  deleteGame: db.prepare(`DELETE FROM games WHERE id = ?`),
  insertPlayer: db.prepare(`INSERT INTO players (id, name, phone) VALUES (?, ?, ?)`),
  insertJoin: db.prepare(`INSERT INTO joins (gameId, playerId, timestamp, skillLevel) VALUES (?, ?, ?, ?)`),
  getJoinedPlayers: db.prepare(`SELECT p.id, p.name, p.phone, j.timestamp, j.skillLevel FROM joins j JOIN players p ON p.id = j.playerId WHERE j.gameId = ? ORDER BY j.timestamp`),
  getPlayerCount: db.prepare(`SELECT COUNT(*) as count FROM joins WHERE gameId = ?`),
  getJoin: db.prepare(`SELECT * FROM joins WHERE gameId = ? AND playerId = ?`),
  updateSkillLevel: db.prepare(`UPDATE joins SET skillLevel = ? WHERE gameId = ? AND playerId = ?`),
  deleteJoin: db.prepare(`DELETE FROM joins WHERE gameId = ? AND playerId = ?`),
  deleteGameJoins: db.prepare(`DELETE FROM joins WHERE gameId = ?`),
  getPublicGames: db.prepare(`SELECT * FROM games WHERE isPublic = 1 AND time >= ?`),
  getGamesByCreator: db.prepare(`SELECT * FROM games WHERE creatorPhone = ? AND time >= ?`),
  getAllRecentGames: db.prepare(`SELECT * FROM games WHERE time >= ?`),
  phoneInGame: db.prepare(`SELECT 1 FROM joins j JOIN players p ON p.id = j.playerId WHERE j.gameId = ? AND p.phone = ? LIMIT 1`),
};

// Helper: Get joined players for a game
function getJoinedPlayers(gameId) {
  return stmts.getJoinedPlayers.all(gameId).map(row => ({
    ...row,
    skillLevel: row.skillLevel || null
  }));
}

// Helper: Get player count for a game
function getPlayerCount(gameId) {
  return stmts.getPlayerCount.get(gameId).count;
}

// Helper: Update game status based on player count
function updateGameStatus(gameId) {
  const game = stmts.getGame.get(gameId);
  if (!game || game.status === 'locked') return;

  const count = getPlayerCount(gameId);
  const newStatus = count >= game.maxPlayers ? 'full' : 'open';
  stmts.updateGameStatus.run(newStatus, gameId);
}

// Helper: format game row (isPublic int -> bool)
function formatGame(row) {
  return { ...row, isPublic: !!row.isPublic };
}

// POST /games - Create a new game
router.post('/', (req, res) => {
  try {
    const { sport, time, location, level, maxPlayers, isPublic, creatorPhone } = req.body;

    if (!sport || !time || !location || !level || !maxPlayers) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const id = uuidv4();
    const createdAt = new Date().toISOString();

    stmts.insertGame.run(id, sport, time, location, level, maxPlayers, isPublic ? 1 : 0, creatorPhone || null, 'open', createdAt);

    const baseUrl = process.env.BASE_URL || `http://${req.get('host')}`;
    const joinUrl = `${baseUrl}/join/${id}`;

    res.status(201).json({
      id, sport, time, location, level, maxPlayers,
      isPublic: isPublic || false,
      creatorPhone: creatorPhone || null,
      status: 'open',
      createdAt,
      joinUrl,
      players: [],
      playerCount: 0
    });
  } catch (error) {
    console.error('Create game error:', error);
    res.status(500).json({ error: 'Failed to create game' });
  }
});

// GET /games - List public games only (for Discover)
router.get('/', (req, res) => {
  try {
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();

    const games = stmts.getPublicGames.all(twoHoursAgo).map(row => {
      const game = formatGame(row);
      const players = getJoinedPlayers(game.id);
      return { ...game, playerCount: players.length, players };
    });

    games.sort((a, b) => new Date(a.time) - new Date(b.time));
    res.json(games);
  } catch (error) {
    console.error('List games error:', error);
    res.status(500).json({ error: 'Failed to fetch games' });
  }
});

// GET /games/my/:phone - List games created by or joined by a phone number
router.get('/my/:phone', (req, res) => {
  try {
    const phone = req.params.phone;
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString();

    const allGames = stmts.getAllRecentGames.all(twoHoursAgo);
    const myGames = [];

    for (const row of allGames) {
      const game = formatGame(row);
      const isCreator = game.creatorPhone === phone;
      const players = getJoinedPlayers(game.id);
      const isPlayer = players.some(p => p.phone === phone);

      if (isCreator || isPlayer) {
        myGames.push({
          ...game,
          playerCount: players.length,
          players,
          isCreator
        });
      }
    }

    myGames.sort((a, b) => new Date(a.time) - new Date(b.time));
    res.json(myGames);
  } catch (error) {
    console.error('List my games error:', error);
    res.status(500).json({ error: 'Failed to fetch your games' });
  }
});

// GET /games/:id - Get game details
router.get('/:id', (req, res) => {
  try {
    const row = stmts.getGame.get(req.params.id);

    if (!row) {
      return res.status(404).json({ error: 'Game not found' });
    }

    const game = formatGame(row);
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

    // Validate phone is exactly 10 digits
    const digitsOnly = phone.replace(/\D/g, '');
    if (digitsOnly.length !== 10) {
      return res.status(400).json({ error: 'Phone number must be exactly 10 digits' });
    }

    const row = stmts.getGame.get(gameId);

    if (!row) {
      return res.status(404).json({ error: 'Game not found' });
    }

    const game = formatGame(row);

    if (game.status === 'locked') {
      return res.status(400).json({ error: 'Game is locked' });
    }

    // Check if phone already exists in this game
    if (stmts.phoneInGame.get(gameId, phone.trim())) {
      return res.status(400).json({ error: 'This phone number is already registered for this game' });
    }

    const currentCount = getPlayerCount(gameId);

    if (currentCount >= game.maxPlayers) {
      return res.status(400).json({ error: 'Game is full' });
    }

    // Create player and join in a transaction
    const playerId = uuidv4();
    const joinTransaction = db.transaction(() => {
      stmts.insertPlayer.run(playerId, name.trim(), phone.trim());
      stmts.insertJoin.run(gameId, playerId, new Date().toISOString(), null);
      updateGameStatus(gameId);
    });
    joinTransaction();

    const updatedGame = formatGame(stmts.getGame.get(gameId));
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

// PATCH /games/:id - Update game status or visibility
router.patch('/:id', (req, res) => {
  try {
    const { status, isPublic } = req.body;
    const gameId = req.params.id;

    const row = stmts.getGame.get(gameId);

    if (!row) {
      return res.status(404).json({ error: 'Game not found' });
    }

    if (status && ['open', 'full', 'locked', 'cancelled'].includes(status)) {
      stmts.updateGameStatus.run(status, gameId);
    }

    if (typeof isPublic === 'boolean') {
      stmts.updateGameVisibility.run(isPublic ? 1 : 0, gameId);
    }

    const updatedGame = formatGame(stmts.getGame.get(gameId));
    const players = getJoinedPlayers(gameId);
    const baseUrl = process.env.BASE_URL || `http://${req.get('host')}`;

    res.json({
      ...updatedGame,
      joinUrl: `${baseUrl}/join/${gameId}`,
      players,
      playerCount: players.length
    });
  } catch (error) {
    console.error('Update game error:', error);
    res.status(500).json({ error: 'Failed to update game' });
  }
});

// PATCH /games/:id/players/:playerId - Update player skill level
router.patch('/:id/players/:playerId', (req, res) => {
  try {
    const { skillLevel } = req.body;
    const gameId = req.params.id;
    const playerId = req.params.playerId;

    const row = stmts.getGame.get(gameId);
    if (!row) {
      return res.status(404).json({ error: 'Game not found' });
    }

    const join = stmts.getJoin.get(gameId, playerId);
    if (!join) {
      return res.status(404).json({ error: 'Player not found in this game' });
    }

    // Update skill level (1-5) or null to remove
    if (skillLevel === null || (skillLevel >= 1 && skillLevel <= 5)) {
      stmts.updateSkillLevel.run(skillLevel, gameId, playerId);
    } else {
      return res.status(400).json({ error: 'Skill level must be between 1 and 5' });
    }

    const game = formatGame(stmts.getGame.get(gameId));
    const players = getJoinedPlayers(gameId);
    const baseUrl = process.env.BASE_URL || `http://${req.get('host')}`;

    res.json({
      ...game,
      joinUrl: `${baseUrl}/join/${gameId}`,
      players,
      playerCount: players.length
    });
  } catch (error) {
    console.error('Update player skill error:', error);
    res.status(500).json({ error: 'Failed to update player skill' });
  }
});

// DELETE /games/:id/players/:playerId - Remove player from game (deregister)
router.delete('/:id/players/:playerId', (req, res) => {
  try {
    const gameId = req.params.id;
    const playerId = req.params.playerId;

    const row = stmts.getGame.get(gameId);
    if (!row) {
      return res.status(404).json({ error: 'Game not found' });
    }

    const join = stmts.getJoin.get(gameId, playerId);
    if (!join) {
      return res.status(404).json({ error: 'Player not found in this game' });
    }

    stmts.deleteJoin.run(gameId, playerId);
    updateGameStatus(gameId);

    const updatedGame = formatGame(stmts.getGame.get(gameId));
    const players = getJoinedPlayers(gameId);
    const baseUrl = process.env.BASE_URL || `http://${req.get('host')}`;

    res.json({
      success: true,
      message: 'You have been removed from this game',
      game: {
        ...updatedGame,
        joinUrl: `${baseUrl}/join/${gameId}`,
        players,
        playerCount: players.length
      }
    });
  } catch (error) {
    console.error('Remove player error:', error);
    res.status(500).json({ error: 'Failed to remove player' });
  }
});

// DELETE /games/:id - Delete a game
router.delete('/:id', (req, res) => {
  try {
    const gameId = req.params.id;

    const row = stmts.getGame.get(gameId);
    if (!row) {
      return res.status(404).json({ error: 'Game not found' });
    }

    const deleteTransaction = db.transaction(() => {
      stmts.deleteGameJoins.run(gameId);
      stmts.deleteGame.run(gameId);
    });
    deleteTransaction();

    res.json({ success: true });
  } catch (error) {
    console.error('Delete game error:', error);
    res.status(500).json({ error: 'Failed to delete game' });
  }
});

module.exports = router;
