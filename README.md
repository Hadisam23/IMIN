# Sports Coordinator MVP

A simple app for organizing sports games. Organizers use the iOS app, players join via web link.

## Project Structure

```
sports-coordinator/
├── backend/           # Node.js + Express server
│   ├── server.js      # Main server entry
│   ├── db.js          # SQLite database setup
│   ├── routes/games.js # API routes
│   └── public/join.html # Web join page
└── ios/               # SwiftUI app
    └── SportsCoordinator/
        ├── Models/
        ├── Services/
        └── Views/
```

## Setup Instructions

### 1. Backend Setup

```bash
cd sports-coordinator/backend

# Install dependencies
npm install

# Start the server
npm start
```

The server runs on `http://localhost:3000`

### 2. iOS App Setup

1. Open Xcode and create a new iOS App project:
   - Product Name: `SportsCoordinator`
   - Interface: `SwiftUI`
   - Language: `Swift`

2. Delete the auto-generated `ContentView.swift`

3. Copy all files from `ios/SportsCoordinator/` into your Xcode project:
   - `Models/Game.swift`
   - `Models/Player.swift`
   - `Services/APIService.swift`
   - `Views/HomeView.swift`
   - `Views/CreateGameView.swift`
   - `Views/GameDashboardView.swift`
   - Replace `SportsCoordinatorApp.swift`

4. **Important for physical device testing:**
   Edit `APIService.swift` and update the `baseURL` with your Mac's local IP:
   ```swift
   private let baseURL = "http://YOUR_MAC_IP:3000"
   ```
   Find your IP: System Preferences → Network → Wi-Fi → IP Address

5. Build and run on simulator or device

### 3. Testing the Flow

1. **Start the backend** (keep terminal open)

2. **Run the iOS app** on simulator

3. **Create a game:**
   - Tap the + button
   - Fill in sport, date, location, level, max players
   - Tap "Create & Get Link"
   - Share the link

4. **Test the web join page:**
   - Open the join URL in a browser: `http://localhost:3000/join/{gameId}`
   - Enter a name and click "I'm In!"
   - The iOS app dashboard will show the new player (auto-refreshes every 5s)

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/games` | Create a new game |
| GET | `/games` | List all games |
| GET | `/games/:id` | Get game details |
| POST | `/games/:id/join` | Join a game |
| PATCH | `/games/:id` | Update game status |
| DELETE | `/games/:id` | Delete a game |

### Example: Create Game

```bash
curl -X POST http://localhost:3000/games \
  -H "Content-Type: application/json" \
  -d '{
    "sport": "Football",
    "time": "2025-01-25T16:00:00Z",
    "location": "Central Park Field 3",
    "level": "Intermediate",
    "maxPlayers": 10
  }'
```

### Example: Join Game

```bash
curl -X POST http://localhost:3000/games/{gameId}/join \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith",
    "phone": "555-1234"
  }'
```

## Exposing for External Testing

To let others join from WhatsApp:

### Option A: ngrok (recommended for testing)

```bash
# Install ngrok
brew install ngrok

# Expose your server
ngrok http 3000
```

Copy the ngrok URL and set it as `BASE_URL`:

```bash
BASE_URL=https://abc123.ngrok.io npm start
```

### Option B: Deploy to cloud

Deploy the backend folder to Render, Railway, or Heroku.

## Features Included

- [x] Create games with sport, time, location, level, max players
- [x] Generate shareable join URL
- [x] Web page for players to join without app
- [x] Real-time roster view with auto-refresh
- [x] Progress bar showing spots filled
- [x] Lock/Cancel game functionality
- [x] Prevent joining when game is full
- [x] Share sheet integration

## Not Included (MVP scope)

- Authentication / user accounts
- Push notifications
- Player profiles
- Payment handling
- Chat functionality
- Recurring games
