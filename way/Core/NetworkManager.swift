//
//  NetworkManager.swift
//  way
//
//  Created by 김상훈 on 7/29/25.
//


// 📁 Core/NetworkManager.swift
import Foundation

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "http://localhost:3000/api"
    private var authToken: String?
    
    private init() {}
    
    // MARK: - 인증 관련
    func register(email: String, password: String, playerName: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password,
            "playerName": playerName
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw NetworkError.invalidResponse
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.token
        return authResponse
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.authToken = authResponse.token
        return authResponse
    }
    
    // MARK: - 게임 데이터
    func getPlayerData() async throws -> PlayerData {
        let url = URL(string: "\(baseURL)/game/player/data")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(authToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(PlayerData.self, from: data)
    }
    
    func buyItem(merchantId: String, itemName: String) async throws -> TradeResponse {
        let url = URL(string: "\(baseURL)/game/trade/buy")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken ?? "")", forHTTPHeaderField: "Authorization")
        
        let body = ["merchantId": merchantId, "itemName": itemName]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(TradeResponse.self, from: data)
    }
}

// MARK: - 에러 정의
enum NetworkError: LocalizedError {
    case invalidResponse
    case unauthorized
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "잘못된 응답입니다"
        case .unauthorized: return "인증이 필요합니다"
        case .serverError: return "서버 오류가 발생했습니다"
        }
    }
}

// MARK: - Response 모델
struct AuthResponse: Codable {
    let success: Bool
    let token: String?
    let user: UserInfo?
    let player: PlayerInfo?
    let error: String?
}

struct PlayerData: Codable {
    let success: Bool
    let data: PlayerDetail?
    let error: String?
}

struct TradeResponse: Codable {
    let success: Bool
    let data: TradeResult?
    let error: String?
}