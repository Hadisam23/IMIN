import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        }
    }
}

final class APIService: Sendable {
    static let shared = APIService()

    private init() {}

    // Production API
    private let baseURL = "https://imin-production.up.railway.app"

    private var decoder: JSONDecoder { JSONDecoder() }
    private var encoder: JSONEncoder { JSONEncoder() }

    // MARK: - Games

    func fetchGames() async throws -> [Game] {
        guard let url = URL(string: "\(baseURL)/games") else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                throw APIError.serverError("Failed to fetch games")
            }

            return try decoder.decode([Game].self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func fetchMyGames(phone: String) async throws -> [Game] {
        guard let encodedPhone = phone.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/games/my/\(encodedPhone)") else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                throw APIError.serverError("Failed to fetch your games")
            }

            return try decoder.decode([Game].self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func fetchGame(id: String) async throws -> Game {
        guard let url = URL(string: "\(baseURL)/games/\(id)") else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 404 {
                throw APIError.serverError("Game not found")
            }

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                throw APIError.serverError("Failed to fetch game")
            }

            return try decoder.decode(Game.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func createGame(sport: String, time: Date, location: String, level: String, maxPlayers: Int, isPublic: Bool = false, creatorPhone: String? = nil) async throws -> Game {
        guard let url = URL(string: "\(baseURL)/games") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let formatter = ISO8601DateFormatter()
        let timeString = formatter.string(from: time)

        let body = CreateGameRequest(
            sport: sport,
            time: timeString,
            location: location,
            level: level,
            maxPlayers: maxPlayers,
            isPublic: isPublic,
            creatorPhone: creatorPhone
        )

        request.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorResponse["error"] {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.serverError("Failed to create game")
            }

            return try decoder.decode(Game.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func updateGame(id: String, status: GameStatus) async throws -> Game {
        guard let url = URL(string: "\(baseURL)/games/\(id)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = UpdateGameRequest(status: status.rawValue)
        request.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                throw APIError.serverError("Failed to update game")
            }

            return try decoder.decode(Game.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func updateGameVisibility(id: String, isPublic: Bool) async throws -> Game {
        guard let url = URL(string: "\(baseURL)/games/\(id)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["isPublic": isPublic]
        request.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                throw APIError.serverError("Failed to update game visibility")
            }

            return try decoder.decode(Game.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    func deleteGame(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/games/\(id)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                throw APIError.serverError("Failed to delete game")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func joinGame(id: String, name: String, phone: String? = nil) async throws -> Game {
        guard let url = URL(string: "\(baseURL)/games/\(id)/join") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = JoinRequest(name: name, phone: phone)
        request.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorResponse["error"] {
                    throw APIError.serverError(errorMessage)
                }
                throw APIError.serverError("Failed to join game")
            }

            let joinResponse = try decoder.decode(JoinResponse.self, from: data)
            if let game = joinResponse.game {
                return game
            }
            // If no game in response, fetch it
            return try await fetchGame(id: id)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}
