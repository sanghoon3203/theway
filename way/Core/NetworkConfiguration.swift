// 📁 Core/NetworkConfiguration.swift
import Foundation

struct NetworkConfiguration {
    
    // MARK: - Server Configuration
    
    #if DEBUG
    // 개발 환경 설정 (iOS 시뮬레이터는 IPv4 주소 강제 사용)
    static let serverHost = "127.0.0.1"
    static let serverPort = 3001
    #else
    // 프로덕션 환경 설정 (추후 실제 서버 주소로 변경)
    static let serverHost = "your-production-server.com"
    static let serverPort = 443
    #endif
    
    // MARK: - Computed Properties
    
    static var baseURL: String {
        #if DEBUG
        return "http://\(serverHost):\(serverPort)/api"
        #else
        return "https://\(serverHost)/api"
        #endif
    }
    
    static var socketURL: String {
        #if DEBUG
        return "http://\(serverHost):\(serverPort)"
        #else
        return "https://\(serverHost)"
        #endif
    }
    
    static var webSocketURL: String {
        #if DEBUG
        return "ws://\(serverHost):\(serverPort)"
        #else
        return "wss://\(serverHost)"
        #endif
    }
    
    // MARK: - API Endpoints
    
    enum Endpoint {
        case auth(AuthEndpoint)
        case game(GameEndpoint)
        case health
        
        var path: String {
            switch self {
            case .auth(let authEndpoint):
                return "/auth" + authEndpoint.path
            case .game(let gameEndpoint):
                return "/game" + gameEndpoint.path
            case .health:
                return "/health"
            }
        }
        
        var fullURL: String {
            switch self {
            case .health:
                return "http://\(serverHost):\(serverPort)" + path
            default:
                return baseURL + path
            }
        }
    }
    
    enum AuthEndpoint {
        case register
        case login
        case refresh
        
        var path: String {
            switch self {
            case .register: return "/register"
            case .login: return "/login"
            case .refresh: return "/refresh"
            }
        }
    }
    
    enum GameEndpoint {
        case playerData
        case playerLocation
        case marketPrices
        case merchants
        case tradeBuy
        case tradeSell
        case tradeHistory
        case achievements
        case achievementProgress
        case achievementClaim(String)
        
        var path: String {
            switch self {
            case .playerData: return "/player/data"
            case .playerLocation: return "/player/location"
            case .marketPrices: return "/market/prices"
            case .merchants: return "/merchants"
            case .tradeBuy: return "/trade/buy"
            case .tradeSell: return "/trade/sell"
            case .tradeHistory: return "/trade/history"
            case .achievements: return "/achievements"
            case .achievementProgress: return "/achievements/progress"
            case .achievementClaim(let id): return "/achievements/\(id)/claim"
            }
        }
    }
    
    // MARK: - Network Settings
    
    static let requestTimeout: TimeInterval = 15.0
    static let resourceTimeout: TimeInterval = 30.0
    static let maxRetryCount = 3
    static let retryDelay: TimeInterval = 1.0
    static let cacheTimeout: TimeInterval = 300 // 5분
    
    // MARK: - Development Helper
    
    static func printCurrentConfiguration() {
        print("🌐 Network Configuration:")
        print("📍 Base URL: \(baseURL)")
        print("🔌 Socket URL: \(socketURL)")
        print("💊 Health URL: \(Endpoint.health.fullURL)")
        print("🏗 Environment: \(isDebug ? "DEBUG" : "RELEASE")")
    }
    
    private static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}