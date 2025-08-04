// 📁 Core/NetworkManager.swift - 수정된 버전
import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var lastError: NetworkError?
    
    // MARK: - Private Properties
    private var authToken: String? {
        didSet {
            isAuthenticated = authToken != nil
            if authToken != nil {
                UserDefaults.standard.set(authToken, forKey: "auth_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "auth_token")
            }
        }
    }
    
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    // ✅ 요청 캐시 및 중복 방지
    private var activeRequests: [String: Task<Any, Error>] = [:]
    private var requestCache: [String: (data: Data, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5분 캐시
    
    // ✅ 재시도 설정
    private let maxRetryCount = 3
    private let retryDelay: TimeInterval = 1.0
    
    // MARK: - Configuration
    private let baseURL = "http://localhost:3000/api"
    
    private init() {
        // ✅ URLSession 설정 최적화
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024)
        
        self.session = URLSession(configuration: config)
        
        // 저장된 토큰 복원
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            self.authToken = token
        }
        
        // ✅ 주기적 캐시 정리
        setupCacheCleanup()
    }
    
    deinit {
        // ✅ 진행 중인 요청 취소
        activeRequests.values.forEach { $0.cancel() }
    }
}

// MARK: - Cache Management
extension NetworkManager {
    private func setupCacheCleanup() {
        Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.cleanupCache()
        }
    }
    
    private func cleanupCache() {
        let now = Date()
        requestCache = requestCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < cacheTimeout
        }
    }
    
    private func getCachedResponse(for key: String) -> Data? {
        if let cached = requestCache[key],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.data
        }
        return nil
    }
    
    private func setCachedResponse(_ data: Data, for key: String) {
        requestCache[key] = (data: data, timestamp: Date())
    }
}

// MARK: - Network Request Methods
extension NetworkManager {
    // ✅ 개선된 네트워크 요청 메서드
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        requiresAuth: Bool = false,
        responseType: T.Type,
        useCache: Bool = false,
        retryCount: Int = 0
    ) async throws -> T {
        
        // ✅ 중복 요청 방지
        let requestKey = "\(method.rawValue)-\(endpoint)-\(body?.description ?? "")"
        
        if let activeTask = activeRequests[requestKey] {
            return try await activeTask.value as! T
        }
        
        // ✅ 캐시 확인 (GET 요청만)
        if method == .GET && useCache,
           let cachedData = getCachedResponse(for: requestKey) {
            do {
                let response = try JSONDecoder().decode(T.self, from: cachedData)
                return response
            } catch {
                // 캐시된 데이터가 잘못된 경우 캐시 삭제
                requestCache.removeValue(forKey: requestKey)
            }
        }
        
        let task = Task<Any, Error> {
            return try await performRequest(
                endpoint: endpoint,
                method: method,
                body: body,
                requiresAuth: requiresAuth,
                responseType: responseType,
                useCache: useCache,
                requestKey: requestKey,
                retryCount: retryCount
            )
        }
        
        activeRequests[requestKey] = task
        
        defer {
            activeRequests.removeValue(forKey: requestKey)
        }
        
        return try await task.value as! T
    }
    
    private func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: [String: Any]?,
        requiresAuth: Bool,
        responseType: T.Type,
        useCache: Bool,
        requestKey: String,
        retryCount: Int
    ) async throws -> T {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ 인증 헤더 추가
        if requiresAuth {
            guard let token = authToken else {
                await MainActor.run { self.lastError = .unauthorized }
                throw NetworkError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // ✅ 요청 본문 추가
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                throw NetworkError.invalidRequest
            }
        }
        
        do {
            await MainActor.run { self.isLoading = true }
            
            let (data, response) = try await session.data(for: request)
            
            await MainActor.run { self.isLoading = false }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // ✅ HTTP 상태 코드 처리
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                await MainActor.run {
                    self.logout() // 자동 로그아웃
                }
                throw NetworkError.unauthorized
            case 400...499:
                throw NetworkError.clientError(httpResponse.statusCode)
            case 500...599:
                // ✅ 서버 오류 시 재시도
                if retryCount < maxRetryCount {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(retryCount + 1) * 1_000_000_000))
                    return try await performRequest(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        requiresAuth: requiresAuth,
                        responseType: responseType,
                        useCache: useCache,
                        requestKey: requestKey,
                        retryCount: retryCount + 1
                    )
                }
                throw NetworkError.serverError
            default:
                throw NetworkError.invalidResponse
            }
            
            // ✅ JSON 파싱
            do {
                let response = try JSONDecoder().decode(T.self, from: data)
                
                // ✅ 성공적인 GET 요청은 캐시에 저장
                if method == .GET && useCache {
                    setCachedResponse(data, for: requestKey)
                }
                
                await MainActor.run { self.lastError = nil }
                return response
                
            } catch {
                print("❌ JSON 파싱 오류: \(error)")
                throw NetworkError.invalidResponse
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                if let networkError = error as? NetworkError {
                    self.lastError = networkError
                } else {
                    self.lastError = .networkError(error)
                }
            }
            throw error
        }
    }
}

// MARK: - Authentication API
extension NetworkManager {
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
        
        // ✅ 성공 시 토큰 저장 및 Socket 연결
        if response.success, let token = response.token {
            await MainActor.run {
                self.authToken = token
                SocketManager.shared.connect(with: token)
            }
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
        
        // ✅ 성공 시 토큰 저장 및 Socket 연결
        if response.success, let token = response.token {
            await MainActor.run {
                self.authToken = token
                SocketManager.shared.connect(with: token)
            }
        }
        
        return response
    }
    
    func logout() {
        authToken = nil
        isAuthenticated = false
        
        // ✅ Socket 연결 해제
        SocketManager.shared.disconnect()
        
        // ✅ 캐시 정리
        requestCache.removeAll()
        activeRequests.values.forEach { $0.cancel() }
        activeRequests.removeAll()
        
        print("🔓 로그아웃 완료")
    }
    
    // ✅ 토큰 갱신
    func refreshToken() async throws -> AuthResponse {
        let response: AuthResponse = try await makeRequest(
            endpoint: "/auth/refresh",
            method: .POST,
            requiresAuth: true,
            responseType: AuthResponse.self
        )
        
        if response.success, let token = response.token {
            await MainActor.run {
                self.authToken = token
            }
        }
        
        return response
    }
}

// MARK: - Game Data API
extension NetworkManager {
    func getPlayerData() async throws -> PlayerDataResponse {
        return try await makeRequest(
            endpoint: "/game/player/data",
            requiresAuth: true,
            responseType: PlayerDataResponse.self,
            useCache: true
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
    
    func getMarketPrices() async throws -> MarketPricesResponse {
        return try await makeRequest(
            endpoint: "/game/market/prices",
            responseType: MarketPricesResponse.self,
            useCache: true
        )
    }
    
    func getMerchants(latitude: Double? = nil, longitude: Double? = nil) async throws -> MerchantsResponse {
        var endpoint = "/game/merchants"
        
        if let lat = latitude, let lng = longitude {
            endpoint += "?lat=\(lat)&lng=\(lng)"
        }
        
        return try await makeRequest(
            endpoint: endpoint,
            responseType: MerchantsResponse.self,
            useCache: true
        )
    }
    
    // ✅ 거래 API
    func buyItem(merchantId: String, itemName: String) async throws -> TradeResponse {
        let body = [
            "merchantId": merchantId,
            "itemName": itemName
        ]
        
        return try await makeRequest(
            endpoint: "/game/trade/buy",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: TradeResponse.self
        )
    }
    
    func sellItem(itemId: String, merchantId: String) async throws -> TradeResponse {
        let body = [
            "itemId": itemId,
            "merchantId": merchantId
        ]
        
        return try await makeRequest(
            endpoint: "/game/trade/sell",
            method: .POST,
            body: body,
            requiresAuth: true,
            responseType: TradeResponse.self
        )
    }
    
    func getTradeHistory(limit: Int = 20, offset: Int = 0) async throws -> TradeHistoryResponse {
        return try await makeRequest(
            endpoint: "/game/trade/history?limit=\(limit)&offset=\(offset)",
            requiresAuth: true,
            responseType: TradeHistoryResponse.self,
            useCache: true
        )
    }
}

// MARK: - HTTP Method Enum
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidRequest
    case unauthorized
    case invalidResponse
    case clientError(Int)
    case serverError
    case networkError(Error)
    case timeout
    case noInternetConnection
    
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
        case .clientError(let code):
            return "클라이언트 오류 (코드: \(code))"
        case .serverError:
            return "서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요"
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .timeout:
            return "요청 시간이 초과되었습니다"
        case .noInternetConnection:
            return "인터넷 연결을 확인해주세요"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "로그인 페이지로 이동하겠습니다"
        case .serverError:
            return "잠시 후 다시 시도해주세요"
        case .noInternetConnection:
            return "네트워크 연결을 확인하고 다시 시도해주세요"
        default:
            return nil
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

struct TradeHistoryResponse: Codable {
    let success: Bool
    let data: TradeHistoryData?
    let error: String?
}

// MARK: - Data Models
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

struct PlayerDetail: Codable {
    let id: String
    let name: String
    let money: Int
    let trustPoints: Int
    let currentLicense: Int
    let maxInventorySize: Int
    let location: LocationData
    let inventory: [InventoryItem]
    let inventoryCount: Int
}

struct LocationData: Codable {
    let lat: Double
    let lng: Double
}

struct InventoryItem: Codable {
    let id: String
    let name: String
    let category: String
    let basePrice: Int
    let currentPrice: Int
    let grade: String
    let requiredLicense: Int
    let acquiredAt: String
}

struct MarketPrice: Codable {
    let id: String
    let itemName: String
    let basePrice: Int
    let currentPrice: Int
    let lastUpdated: String
}

struct MerchantData: Codable {
    let id: String
    let name: String
    let type: String
    let district: String
    let location: LocationData
    let requiredLicense: Int
    let inventory: [TradeItem]
    let distance: Double?
}

struct TradeResult: Codable {
    let newMoney: Int
    let newTrustPoints: Int
    let tradeId: String
    let purchasedItem: PurchasedItem?
    let soldItem: SoldItem?
}

struct PurchasedItem: Codable {
    let id: String
    let name: String
    let category: String
    let purchasePrice: Int
    let grade: String
}

struct SoldItem: Codable {
    let name: String
    let category: String
    let sellPrice: Int
}

struct TradeHistoryData: Codable {
    let trades: [TradeRecord]
    let pagination: PaginationInfo
}

struct TradeRecord: Codable {
    let id: String
    let itemName: String
    let itemCategory: String
    let price: Int
    let type: String
    let timestamp: String
    let location: LocationData
}

struct PaginationInfo: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
}
