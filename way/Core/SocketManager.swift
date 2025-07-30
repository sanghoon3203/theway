// 📁 Core/SocketManager.swift
import Foundation
import SocketIO
import Combine
import CoreLocation

#if canImport(UIKit)
import UIKit
#endif

class SocketManager: ObservableObject {
    static let shared = SocketManager()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var nearbyMerchants: [Merchant] = []
    @Published var priceUpdates: [String: Int] = [:]
    @Published var realTimeEvents: [GameEvent] = []
    @Published var playersInArea: [PlayerLocation] = []
    
    // MARK: - Private Properties
    private var manager: SocketIO.SocketManager?
    private var socket: SocketIOClient?
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    private var lastPingTime: Date?
    private var connectionRetryCount = 0
    private let maxRetryCount = 5
    
    // MARK: - Configuration
    private let serverURL = "http://localhost:3000"
    private let socketConfig: SocketIOClientConfiguration = [
        .log(false), // 프로덕션에서는 false
        .compress,
        .reconnects(true),
        .reconnectWait(3),
        .reconnectWaitMax(10),
        .randomizationFactor(0.5),
        .connectParams(["transport": "websocket"]),
        .forceWebsockets(true)
    ]
    
    private init() {
        setupSocketManager()
    }
    
    deinit {
        disconnect()
        reconnectTimer?.invalidate()
        heartbeatTimer?.invalidate()
    }
}

// MARK: - Connection Management
extension SocketManager {
    func connect(with token: String? = nil) {
        guard let url = URL(string: serverURL) else {
            print("❌ Invalid server URL")
            return
        }
        
        connectionStatus = .connecting
        
        // 토큰이 있으면 인증 헤더 추가
        var config = socketConfig
        if let token = token {
            config.insert(.extraHeaders(["Authorization": "Bearer \(token)"]))
        }
        
        manager = SocketIO.SocketManager(socketURL: url, config: config)
        socket = manager?.defaultSocket
        
        setupEventListeners()
        socket?.connect()
        
        print("🔌 Socket 연결 시도 중...")
    }
    
    func disconnect() {
        connectionStatus = .disconnecting
        
        heartbeatTimer?.invalidate()
        reconnectTimer?.invalidate()
        
        socket?.disconnect()
        socket = nil
        manager = nil
        
        connectionStatus = .disconnected
        isConnected = false
        
        print("🔌 Socket 연결 해제됨")
    }
    
    func reconnect() {
        guard connectionRetryCount < maxRetryCount else {
            print("❌ 최대 재연결 시도 횟수 초과")
            connectionStatus = .failed
            return
        }
        
        connectionRetryCount += 1
        print("🔄 Socket 재연결 시도 \(connectionRetryCount)/\(maxRetryCount)")
        
        disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(connectionRetryCount) * 2) {
            if let token = NetworkManager.shared.isAuthenticated ? self.getStoredToken() : nil {
                self.connect(with: token)
            }
        }
    }
    
    private func getStoredToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}

// MARK: - Socket Setup
extension SocketManager {
    private func setupSocketManager() {
        // 앱이 백그라운드/포그라운드로 전환될 때 처리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        // 백그라운드에서는 연결을 유지하되 빈도를 줄임
        heartbeatTimer?.invalidate()
    }
    
    @objc private func appWillEnterForeground() {
        // 포그라운드로 돌아올 때 연결 상태 확인
        if connectionStatus == .connected {
            startHeartbeat()
        } else if NetworkManager.shared.isAuthenticated {
            reconnect()
        }
    }
    
    private func setupEventListeners() {
        guard let socket = socket else { return }
        
        // MARK: - Connection Events
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handleConnection()
            }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handleDisconnection(data)
            }
        }
        
        socket.on(clientEvent: .error) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handleError(data)
            }
        }
        
        socket.on(clientEvent: .reconnect) { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handleReconnection()
            }
        }
        
        // MARK: - Game Events
        socket.on("welcome") { [weak self] data, ack in
            self?.handleWelcome(data)
        }
        
        socket.on("playerJoined") { [weak self] data, ack in
            self?.handlePlayerJoined(data)
        }
        
        socket.on("playerLeft") { [weak self] data, ack in
            self?.handlePlayerLeft(data)
        }
        
        // MARK: - Market Events
        socket.on("priceUpdate") { [weak self] data, ack in
            self?.handlePriceUpdate(data)
        }
        
        socket.on("marketAlert") { [weak self] data, ack in
            self?.handleMarketAlert(data)
        }
        
        // MARK: - Location Events
        socket.on("nearbyMerchants") { [weak self] data, ack in
            self?.handleNearbyMerchants(data)
        }
        
        socket.on("playersInArea") { [weak self] data, ack in
            self?.handlePlayersInArea(data)
        }
        
        // MARK: - Trade Events
        socket.on("tradeNotification") { [weak self] data, ack in
            self?.handleTradeNotification(data)
        }
        
        // MARK: - System Events
        socket.on("systemMessage") { [weak self] data, ack in
            self?.handleSystemMessage(data)
        }
        
        socket.on("pong") { [weak self] data, ack in
            self?.handlePong()
        }
    }
}

// MARK: - Event Handlers
extension SocketManager {
    private func handleConnection() {
        print("✅ Socket 연결 성공")
        isConnected = true
        connectionStatus = .connected
        connectionRetryCount = 0
        
        startHeartbeat()
        
        // 연결 성공 시 초기 데이터 요청
        requestInitialData()
    }
    
    private func handleDisconnection(_ data: [Any]) {
        print("❌ Socket 연결 해제: \(data)")
        isConnected = false
        connectionStatus = .disconnected
        
        heartbeatTimer?.invalidate()
        
        // 자동 재연결 시도
        if NetworkManager.shared.isAuthenticated {
            scheduleReconnect()
        }
    }
    
    private func handleError(_ data: [Any]) {
        print("❌ Socket 오류: \(data)")
        connectionStatus = .error
        
        if let errorData = data.first as? [String: Any],
           let message = errorData["message"] as? String {
            print("Socket 오류 메시지: \(message)")
        }
    }
    
    private func handleReconnection() {
        print("🔄 Socket 재연결 성공")
        connectionRetryCount = 0
    }
    
    private func handleWelcome(_ data: [Any]) {
        if let welcomeData = data.first as? [String: Any] {
            print("👋 서버 환영 메시지: \(welcomeData)")
            
            if let playerId = welcomeData["playerId"] as? String {
                print("플레이어 ID: \(playerId)")
            }
        }
    }
    
    private func handlePlayerJoined(_ data: [Any]) {
        if let playerData = data.first as? [String: Any],
           let player = parsePlayerLocation(from: playerData) {
            
            DispatchQueue.main.async {
                if !self.playersInArea.contains(where: { $0.id == player.id }) {
                    self.playersInArea.append(player)
                }
            }
        }
    }
    
    private func handlePlayerLeft(_ data: [Any]) {
        if let playerData = data.first as? [String: Any],
           let playerId = playerData["playerId"] as? String {
            
            DispatchQueue.main.async {
                self.playersInArea.removeAll { $0.id == playerId }
            }
        }
    }
    
    private func handlePriceUpdate(_ data: [Any]) {
        if let priceData = data.first as? [String: Any] {
            var updates: [String: Int] = [:]
            
            for (key, value) in priceData {
                if let price = value as? Int {
                    updates[key] = price
                }
            }
            
            DispatchQueue.main.async {
                self.priceUpdates = updates
                
                // 실시간 이벤트로도 추가
                let event = GameEvent(
                    type: .priceUpdate,
                    message: "시장 가격이 업데이트되었습니다",
                    data: priceData
                )
                self.realTimeEvents.append(event)
            }
        }
    }
    
    private func handleMarketAlert(_ data: [Any]) {
        if let alertData = data.first as? [String: Any],
           let message = alertData["message"] as? String,
           let alertType = alertData["type"] as? String {
            
            DispatchQueue.main.async {
                let event = GameEvent(
                    type: GameEventType(rawValue: alertType) ?? .marketAlert,
                    message: message,
                    data: alertData
                )
                self.realTimeEvents.append(event)
            }
        }
    }
    
    private func handleNearbyMerchants(_ data: [Any]) {
        if let merchantsData = data.first as? [[String: Any]] {
            let merchants = merchantsData.compactMap { parseMerchant(from: $0) }
            
            DispatchQueue.main.async {
                self.nearbyMerchants = merchants
            }
        }
    }
    
    private func handlePlayersInArea(_ data: [Any]) {
        if let playersData = data.first as? [[String: Any]] {
            let players = playersData.compactMap { parsePlayerLocation(from: $0) }
            
            DispatchQueue.main.async {
                self.playersInArea = players
            }
        }
    }
    
    private func handleTradeNotification(_ data: [Any]) {
        if let tradeData = data.first as? [String: Any],
           let message = tradeData["message"] as? String {
            
            DispatchQueue.main.async {
                let event = GameEvent(
                    type: .tradeNotification,
                    message: message,
                    data: tradeData
                )
                self.realTimeEvents.append(event)
            }
        }
    }
    
    private func handleSystemMessage(_ data: [Any]) {
        if let messageData = data.first as? [String: Any],
           let message = messageData["message"] as? String {
            
            DispatchQueue.main.async {
                let event = GameEvent(
                    type: .systemMessage,
                    message: message,
                    data: messageData
                )
                self.realTimeEvents.append(event)
            }
        }
    }
    
    private func handlePong() {
        lastPingTime = Date()
    }
}

// MARK: - Data Sending Methods
extension SocketManager {
    func sendLocation(latitude: Double, longitude: Double) {
        guard isConnected else { return }
        
        let locationData: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        socket?.emit("updateLocation", locationData)
    }
    
    func joinRoom(_ roomId: String) {
        guard isConnected else { return }
        
        socket?.emit("joinRoom", roomId)
        print("🏠 방 참가: \(roomId)")
    }
    
    func leaveRoom(_ roomId: String) {
        guard isConnected else { return }
        
        socket?.emit("leaveRoom", roomId)
        print("🚪 방 떠남: \(roomId)")
    }
    
    func sendTradeRequest(merchantId: String, itemName: String, action: String) {
        guard isConnected else { return }
        
        let tradeData: [String: Any] = [
            "merchantId": merchantId,
            "itemName": itemName,
            "action": action, // "buy" or "sell"
            "timestamp": Date().timeIntervalSince1970
        ]
        
        socket?.emit("tradeRequest", tradeData)
    }
    
    func sendChatMessage(message: String, roomId: String? = nil) {
        guard isConnected else { return }
        
        let chatData: [String: Any] = [
            "message": message,
            "roomId": roomId ?? "global",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        socket?.emit("chatMessage", chatData)
    }
    
    func requestMarketData(district: String? = nil) {
        guard isConnected else { return }
        
        var requestData: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let district = district {
            requestData["district"] = district
        }
        
        socket?.emit("requestMarketData", requestData)
    }
    
    func requestNearbyPlayers(latitude: Double, longitude: Double, radius: Double = 1000) {
        guard isConnected else { return }
        
        let requestData: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "radius": radius,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        socket?.emit("requestNearbyPlayers", requestData)
    }
}

// MARK: - Heartbeat & Connection Health
extension SocketManager {
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        guard isConnected else { return }
        
        socket?.emit("ping", Date().timeIntervalSince1970)
        
        // 5초 후에도 pong이 안 오면 연결 문제로 판단
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            
            if let lastPing = self.lastPingTime,
               Date().timeIntervalSince(lastPing) > 30 {
                print("⚠️ Heartbeat 응답 없음 - 재연결 시도")
                self.reconnect()
            }
        }
    }
    
    private func scheduleReconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.reconnect()
        }
    }
    
    private func requestInitialData() {
        // 연결 성공 후 필요한 초기 데이터 요청
        requestMarketData()
        
        // 위치 기반 데이터 요청 (예: 서울 중심부)
        sendLocation(latitude: 37.5665, longitude: 126.9780)
    }
}

// MARK: - Data Parsing Helpers
extension SocketManager {
    private func parseMerchant(from data: [String: Any]) -> Merchant? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let typeString = data["type"] as? String,
              let type = Merchant.MerchantType(rawValue: typeString),
              let districtString = data["district"] as? String,
              let district = SeoulDistrict(rawValue: districtString),
              let licenseValue = data["requiredLicense"] as? Int,
              let license = LicenseLevel(rawValue: licenseValue),
              let locationData = data["location"] as? [String: Double],
              let lat = locationData["lat"],
              let lng = locationData["lng"] else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        let trustLevel = data["trustLevel"] as? Int ?? 0
        
        // 인벤토리 파싱
        var inventory: [TradeItem] = []
        if let inventoryData = data["inventory"] as? [[String: Any]] {
            inventory = inventoryData.compactMap { parseTradeItem(from: $0) }
        }
        
        return Merchant(
            name: name,
            type: type,
            district: district,
            coordinate: coordinate,
            requiredLicense: license,
            inventory: inventory,
            trustLevel: trustLevel
        )
    }
    
    private func parseTradeItem(from data: [String: Any]) -> TradeItem? {
        guard let name = data["name"] as? String,
              let category = data["category"] as? String,
              let basePrice = data["basePrice"] as? Int,
              let currentPrice = data["currentPrice"] as? Int,
              let gradeString = data["grade"] as? String,
              let grade = ItemGrade(rawValue: gradeString),
              let licenseValue = data["requiredLicense"] as? Int,
              let license = LicenseLevel(rawValue: licenseValue) else {
            return nil
        }
        
        return TradeItem(
            name: name,
            category: category,
            basePrice: basePrice,
            grade: grade,
            requiredLicense: license,
            currentPrice: currentPrice
        )
    }
    
    private func parsePlayerLocation(from data: [String: Any]) -> PlayerLocation? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let lat = data["latitude"] as? Double,
              let lng = data["longitude"] as? Double else {
            return nil
        }
        
        let level = data["level"] as? Int ?? 1
        let lastSeen = data["lastSeen"] as? String ?? ""
        
        return PlayerLocation(
            id: id,
            name: name,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            level: level,
            lastSeen: lastSeen
        )
    }
}

// MARK: - Supporting Models
enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error
    case failed
}

struct GameEvent: Identifiable {
    let id = UUID()
    let type: GameEventType
    let message: String
    let data: [String: Any]
    let timestamp = Date()
}

enum GameEventType: String, CaseIterable {
    case priceUpdate = "priceUpdate"
    case marketAlert = "marketAlert"
    case tradeNotification = "tradeNotification"
    case systemMessage = "systemMessage"
    case playerJoined = "playerJoined"
    case playerLeft = "playerLeft"
    case merchantUpdate = "merchantUpdate"
}

struct PlayerLocation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let level: Int
    let lastSeen: String
}
