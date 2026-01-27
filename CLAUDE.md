# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sports Coordinator MVP - A full-stack application for organizing sports games. Organizers create games via an iOS app, players join via a web link.

## Commands

### Backend (Node.js + Express)
```bash
cd backend
npm install       # Install dependencies
npm start         # Run server on port 3000
npm run dev       # Watch mode with node --watch
```

### iOS
Open `ios/ImIn/ImIn.xcodeproj` in Xcode and run on simulator or device. No external dependencies.

## Architecture

### Backend (`backend/`)
- `server.js` - Express app setup and middleware
- `db.js` - In-memory database using Maps (no persistence - data lost on restart)
- `routes/games.js` - All REST API endpoints
- `public/join.html` - Standalone web page for players to join games (vanilla JS, no build step)

### iOS (`ios/ImIn/ImIn/`)
- `ImInApp.swift` - SwiftUI app entry point
- `Theme.swift` - Color system with light/dark mode support (use `Color.accentBlue`, `.successGreen`, `.warningOrange`, `.errorRed`)
- `Models/` - Game and Player data structures
- `Services/APIService.swift` - Network layer with URLSession, async/await
- `Views/` - SwiftUI views (HomeView, CreateGameView, GameDashboardView)

### API Endpoints
| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/games` | Create game |
| GET | `/games` | List games (last 2 hours only) |
| GET | `/games/:id` | Get game with players |
| POST | `/games/:id/join` | Join game |
| PATCH | `/games/:id` | Update status (lock/cancel) |
| DELETE | `/games/:id` | Delete game |
| GET | `/join/:gameId` | Serve join page |

### Data Model
- **Game**: id, sport, time, location, level, maxPlayers, status (open/full/locked/cancelled)
- **Player**: id, name, phone (optional)
- Game status auto-updates to "full" when maxPlayers reached

## Configuration Notes

- **Physical device testing**: Update `baseURL` in `APIService.swift:30-35` with Mac's IP address (simulator uses localhost)
- **Backend URL**: Set `BASE_URL` env var for ngrok/cloud deployment
- **Port**: Default 3000, configurable via `PORT` env var
