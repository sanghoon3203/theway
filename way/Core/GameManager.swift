// Core/NetworkManager.swift - 수정된 버전
import Foundation

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "http://localhost:3000/api"
    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "auth_token") }
    }
    
    private init() {}
    
    // MARK: - Token Management
    func clearToken() {
        authToken = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    var isAuthenticated: Bool {
        return authToken != nil
    }
    
    // MARK: - Private Network Helper
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        requiresAuth: Bool = false,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 인증이 필요한 경우 토큰 추가
        if requiresAuth {
            guard let token = authToken else {
                throw NetworkError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Body 추가
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                throw NetworkError.invalidRequest
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // 응답 로깅 (개발용)
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response (\(httpResponse.statusCode)): \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(T.self, from: data)
            case 401:
                // 토큰 만료 시 자동 로그아웃
                clearToken()
                throw NetworkError.unauthorized
            case 400...499:
                // 에러 메시지 파싱 시도
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw NetworkError.clientError(httpResponse.statusCode, errorResponse.error)
                }
                throw NetworkError.clientError(httpResponse.statusCode, "클라이언트 오류")
            case 500...599:
                throw NetworkError.serverError
            default:
                throw NetworkError.invalidResponse
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - Authentication API
    func register(email: String, password: String, playerName: String) async throws -> AuthResponse {
        let body = [
            "email": email,
            "password": password,
            "playerName": playerName
        ]
        
        let response: AuthResponse = try await makeRequest(
            endpoint: "/auth/register",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
        
        // 성공 시 토큰 저장
        if response.success, let token = response.token {
            self.authToken = token
            print("✅ 회원가입 성공, 토큰 저장됨")
        }
        
        return response
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let body = [
            "email": email,
            "password": password
        ]
        
        let response: AuthResponse = try await makeRequest(
            endpoint: "/auth/login",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
        
        // 성공 시 토큰 저장
        if response.success, let token = response.token {
            self.authToken = token
            print("✅ 로그인 성공, 토큰 저장됨")
        }
        
        return response
    }
    
    func logout() {
        clearToken()
        print("✅ 로그아웃 완료")
    }
    
    // MARK: - Player Data API (수정된 엔드포인트)
    func getPlayerData() async throws -> PlayerDataResponse {
        return try await makeRequest(
            endpoint: "/game/player", // 수정됨: /game/player/data → /game/player
            requiresAuth: true,
            responseType: PlayerDataResponse.self
        )
    }
    
    func updatePlayerLocation(latitude: Double, longitude: Double) async throws -> BaseResponse {
        let body = [
            "latitude": latitude,
            "longitude": longitude
        ]
        
        return try await makeRequest(
            endpoint: "/game/player/location",
            method: .PUT, // 수정됨: POST → PUT
            body: body,
            requiresAuth: true,
            responseType: BaseResponse.self
        )
    }
    
    // MARK: - Market Data API
    func getMarketPrices() async throws -> MarketPricesResponse {
        return try await makeRequest(
            endpoint: "/game/market/prices",
            requiresAuth: false, // 시장 가격은 인증 불필요
            responseType: MarketPricesResponse.self
        )
    }
    
    func getMerchants(latitude: Double? = nil, longitude: Double? = nil, radius: Int = 1000) async throws -> MerchantsResponse {
        var endpoint = "/game/merchants"
        
        // 쿼리 파라미터 추가
        if let lat = latitude, let lng = longitude {
            endpoint += "?latitude=\(lat)&longitude=\(lng)&radius=\(radius)"
        }
        
        return try await makeRequest(
            endpoint: endpoint,
            requiresAuth: false,
            responseType: MerchantsResponse.self
        )
    }
    
    // MARK: - Trading API
    func buyItem(merchantId: String, itemName: String, quantity: Int = 1) async throws -> TradeResponse {
        let body = [
            "merchantId": merchantId,
            "itemName": itemName,
            "quantity": quantity
        ] as [String : Any]
        
        return try await makeRequest(
            endpoint: "/game/trade/buy",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: TradeResponse.self
        )
    }
    
    func sellItem(itemId: String, merchantId: String, quantity: Int = 1) async throws -> TradeResponse {
        let body = [
            "itemId": itemId,
            "merchantId": merchantId,
            "quantity": quantity
        ] as [String : Any]
        
        return try await makeRequest(
            endpoint: "/game/trade/sell",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: TradeResponse.self
        )
    }
    
    func getTradeHistory(page: Int = 1, limit: Int = 20) async throws -> TradeHistoryResponse {
        let endpoint = "/game/trade/history?page=\(page)&limit=\(limit)"
        
        return try await makeRequest(
            endpoint: endpoint,
            requiresAuth: true,
            responseType: TradeHistoryResponse.self
        )
    }
    
    // MARK: - License System
    func upgradeLicense() async throws -> LicenseUpgradeResponse {
        return try await makeRequest(
            endpoint: "/game/license/upgrade",
            method: .POST,
            requiresAuth: true,
            responseType: LicenseUpgradeResponse.self
        )
    }
    
    // MARK: - Stats and Leaderboard
    func getPlayerStats() async throws -> PlayerStatsResponse {
        return try await makeRequest(
            endpoint: "/game/stats/player",
            requiresAuth: true,
            responseType: PlayerStatsResponse.self
        )
    }
    
    func getLeaderboard(type: String = "money", limit: Int = 10) async throws -> LeaderboardResponse {
        let endpoint = "/game/leaderboard?type=\(type)&limit=\(limit)"
        
        return try await makeRequest(
            endpoint: endpoint,
            requiresAuth: false,
            responseType: LeaderboardResponse.self
        )
    }
    
    // MARK: - Daily Bonus
    func claimDailyBonus() async throws -> DailyBonusResponse {
        return try await makeRequest(
            endpoint: "/game/daily-bonus",
            method: .POST,
            requiresAuth: true,
            responseType: DailyBonusResponse.self
        )
    }
}

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidRequest
    case unauthorized
    case invalidResponse
    case clientError(Int, String?)
    case serverError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .invalidRequest:
            return "잘못된 요청입니다"
        case .unauthorized:
            return "인증이 필요합니다. 다시 로그인해주세요"
        case .invalidResponse:
            return "서버 응답을 해석할 수 없습니다"
        case .clientError(let code, let message):
            return message ?? "클라이언트 오류 (코드: \(code))"
        case .serverError:
            return "서버 오류가 발생했습니다"
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        }
    }
}

// MARK: - Response Models
struct ErrorResponse: Codable {
    let success: Bool
    let error: String
}

struct BaseResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

struct AuthResponse: Codable {
    let success: Bool
    let token: String?
    let user: UserInfo?
    let player: PlayerInfo?
    let message: String?
    let error: String?
}

struct UserInfo: Codable {
    let id: String
    let email: String
}

struct PlayerInfo: Codable {
    let id: String
    let name: String
    let money: Int
    let trustPoints: Int
    let currentLicense: Int
    let maxInventorySize: Int
}

struct PlayerDataResponse: Codable {
    let success: Bool
    let data: PlayerDetail?
    let error: String?
}

struct PlayerDetail: Codable {
    let id: String
    let name: String
    let money: Int
    let trustPoints: Int
    let currentLicense: Int
    let maxInventorySize: Int
    let location: LocationData?
    let inventory: [InventoryItem]
    let lastActive: String?
}

struct LocationData: Codable {
    let lat: Double?
    let lng: Double?
}

struct InventoryItem: Codable {
    let id: String
    let name: String
    let category: String
    let basePrice: Int
    let currentPrice: Int
    let grade: String
    let requiredLicense: Int
    let quantity: Int
    let acquiredAt: String
}

struct MarketPricesResponse: Codable {
    let success: Bool
    let data: [MarketPrice]?
    let error: String?
}

struct MarketPrice: Codable {
    let itemName: String
    let district: String
    let basePrice: Int
    let currentPrice: Int
    let demandMultiplier: Double
    let lastUpdated: String
}

struct MerchantsResponse: Codable {
    let success: Bool
    let data: [MerchantData]?
    let error: String?
}

struct MerchantData: Codable {
    let id: String
    let name: String
    let type: String
    let district: String
    let location: LocationData
    let requiredLicense: Int
    let inventory: [String]
    let trustLevel: Int
    let distance: Int? // 미터 단위
}

struct TradeResponse: Codable {
    let success: Bool
    let data: TradeResult?
    let message: String?
    let error: String?
}

struct TradeResult: Codable {
    let itemName: String
    let quantity: Int
    let totalPrice: Int
    let remainingMoney: Int?
    let newMoney: Int?
}

struct TradeHistoryResponse: Codable {
    let success: Bool
    let data: [TradeHistoryItem]?
    let pagination: PaginationInfo?
    let error: String?
}

struct TradeHistoryItem: Codable {
    let id: String
    let itemName: String
    let itemCategory: String
    let price: Int
    let quantity: Int
    let tradeType: String
    let timestamp: String
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
}

struct LicenseUpgradeResponse: Codable {
    let success: Bool
    let data: LicenseUpgradeResult?
    let message: String?
    let error: String?
}

struct LicenseUpgradeResult: Codable {
    let oldLicense: Int
    let newLicense: Int
    let cost: Int
    let newInventorySize: Int
    let remainingMoney: Int
}

struct PlayerStatsResponse: Codable {
    let success: Bool
    let data: PlayerStats?
    let error: String?
}

struct PlayerStats: Codable {
    let playerId: String
    let playerName: String
    let currentMoney: Int
    let trustPoints: Int
    let currentLicense: Int
    let totalTrades: Int
    let totalTradeValue: Int
    let favoriteItem: String?
    let inventoryCount: Int
}

struct LeaderboardResponse: Codable {
    let success: Bool
    let data: [LeaderboardEntry]?
    let error: String?
}

struct LeaderboardEntry: Codable {
    let rank: Int
    let name: String
    let money: Int
    let trustPoints: Int
    let license: Int
}

struct DailyBonusResponse: Codable {
    let success: Bool
    let data: DailyBonusResult?
    let error: String?
}

struct DailyBonusResult: Codable {
    let bonusMoney: Int
    let bonusTrust: Int
    let newMoney: Int
    let newTrust: Int
}
