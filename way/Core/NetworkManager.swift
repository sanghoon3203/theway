// 📁 Core/NetworkManager.swift
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
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(T.self, from: data)
            case 401:
                // 토큰 만료 시 자동 로그아웃
                clearToken()
                throw NetworkError.unauthorized
            case 400...499:
                throw NetworkError.clientError(httpResponse.statusCode)
            case 500...599:
                throw NetworkError.serverError
            default:
                throw NetworkError.invalidResponse
            }
        } catch {
            if error is NetworkError {
                throw error
            } else {
                throw NetworkError.networkError(error)
            }
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
        }
        
        return response
    }
    
    func refreshToken() async throws -> AuthResponse {
        return try await makeRequest(
            endpoint: "/auth/refresh",
            method: .POST,
            requiresAuth: true,
            responseType: AuthResponse.self
        )
    }
    
    // MARK: - Player Data API
    func getPlayerData() async throws -> PlayerDataResponse {
        return try await makeRequest(
            endpoint: "/game/player",
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
            method: .PUT,
            body: body,
            requiresAuth: true,
            responseType: BaseResponse.self
        )
    }
    
    // MARK: - Market Data API
    func getMarketPrices() async throws -> MarketPricesResponse {
        return try await makeRequest(
            endpoint: "/game/market/prices",
            requiresAuth: true,
            responseType: MarketPricesResponse.self
        )
    }
    
    func getMerchants(latitude: Double? = nil, longitude: Double? = nil, radius: Double = 5000) async throws -> MerchantsResponse {
        var endpoint = "/game/merchants"
        
        if let lat = latitude, let lng = longitude {
            endpoint += "?latitude=\(lat)&longitude=\(lng)&radius=\(radius)"
        }
        
        return try await makeRequest(
            endpoint: endpoint,
            requiresAuth: true,
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
    
    // MARK: - License API
    func upgradeLicense() async throws -> LicenseUpgradeResponse {
        return try await makeRequest(
            endpoint: "/game/license/upgrade",
            method: .POST,
            requiresAuth: true,
            responseType: LicenseUpgradeResponse.self
        )
    }
    
    // MARK: - Shop API
    func purchaseVehicle(vehicleId: String) async throws -> PurchaseResponse {
        let body = ["vehicleId": vehicleId]
        
        return try await makeRequest(
            endpoint: "/game/shop/vehicle",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: PurchaseResponse.self
        )
    }
    
    func purchasePet(petId: String) async throws -> PurchaseResponse {
        let body = ["petId": petId]
        
        return try await makeRequest(
            endpoint: "/game/shop/pet",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: PurchaseResponse.self
        )
    }
    
    func purchaseProperty(propertyId: String) async throws -> PurchaseResponse {
        let body = ["propertyId": propertyId]
        
        return try await makeRequest(
            endpoint: "/game/shop/property",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: PurchaseResponse.self
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
    case unauthorized
    case invalidResponse
    case clientError(Int)
    case serverError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .unauthorized:
            return "인증이 필요합니다. 다시 로그인해주세요"
        case .invalidResponse:
            return "서버 응답을 해석할 수 없습니다"
        case .clientError(let code):
            return "클라이언트 오류 (코드: \(code))"
        case .serverError:
            return "서버 오류가 발생했습니다"
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        }
    }
}

// MARK: - Response Models
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

struct PlayerDataResponse: Codable {
    let success: Bool
    let data: PlayerDetail?
    let error: String?
}

struct MarketPricesResponse: Codable {
    let success: Bool
    let data: [MarketPrice]?
    let error: String?
}

struct MerchantsResponse: Codable {
    let success: Bool
    let data: [MerchantData]?
    let error: String?
}

struct TradeResponse: Codable {
    let success: Bool
    let data: TradeResult?
    let error: String?
}

struct LicenseUpgradeResponse: Codable {
    let success: Bool
    let data: LicenseUpgradeResult?
    let error: String?
}

struct PurchaseResponse: Codable {
    let success: Bool
    let data: PurchaseResult?
    let error: String?
}

// MARK: - Data Models
struct UserInfo: Codable {
    let id: String
    let email: String
    let createdAt: String
}

struct PlayerInfo: Codable {
    let id: String
    let name: String
    let money: Int
    let trustPoints: Int
    let currentLicense: Int
    let maxInventorySize: Int
    let level: Int
    let experience: Int
}

struct PlayerDetail: Codable {
    let id: String
    let name: String
    let money: Int
    let trustPoints: Int
    let currentLicense: Int
    let maxInventorySize: Int
    let level: Int
    let experience: Int
    let inventory: [InventoryItem]
    let vehicles: [VehicleData]
    let pets: [PetData]
    let properties: [PropertyData]
    let lastLocation: LocationData?
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

struct MarketPrice: Codable {
    let itemName: String
    let category: String
    let district: String
    let currentPrice: Int
    let trend: String // "up", "down", "stable"
    let lastUpdated: String
}

struct MerchantData: Codable {
    let id: String
    let name: String
    let type: String
    let district: String
    let location: LocationData
    let requiredLicense: Int
    let trustLevel: Int
    let inventory: [MerchantItem]
    let isActive: Bool
}

struct MerchantItem: Codable {
    let name: String
    let category: String
    let price: Int
    let grade: String
    let stock: Int
}

struct LocationData: Codable {
    let lat: Double
    let lng: Double
}

struct TradeResult: Codable {
    let newMoney: Int
    let newTrustPoints: Int
    let newExperience: Int
    let acquiredItem: InventoryItem?
    let soldItem: InventoryItem?
    let profit: Int?
}

struct LicenseUpgradeResult: Codable {
    let newLicense: Int
    let newMaxInventorySize: Int
    let cost: Int
    let newMoney: Int
}

struct PurchaseResult: Codable {
    let newMoney: Int
    let purchasedItem: ShopItem
}

struct ShopItem: Codable {
    let id: String
    let name: String
    let type: String // "vehicle", "pet", "property"
    let price: Int
    let benefits: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, price, benefits
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        price = try container.decode(Int.self, forKey: .price)
        
        // benefits는 유연하게 처리
        if let benefitsData = try? container.decode([String: AnyCodable].self, forKey: .benefits) {
            benefits = benefitsData.mapValues { $0.value }
        } else {
            benefits = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(price, forKey: .price)
        
        let benefitsData = benefits.mapValues { AnyCodable($0) }
        try container.encode(benefitsData, forKey: .benefits)
    }
}

struct VehicleData: Codable {
    let id: String
    let name: String
    let type: String
    let inventoryBonus: Int
    let speedBonus: Double
    let purchasedAt: String
}

struct PetData: Codable {
    let id: String
    let name: String
    let type: String
    let specialAbility: String
    let level: Int
    let experience: Int
    let purchasedAt: String
}

struct PropertyData: Codable {
    let id: String
    let name: String
    let type: String
    let district: String
    let dailyIncome: Int
    let location: LocationData
    let purchasedAt: String
}

// Helper for encoding/decoding Any values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
