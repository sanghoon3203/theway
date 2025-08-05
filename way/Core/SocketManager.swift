// 📁 Core/SocketManager.swift - 완전한 복구 버전
import Foundation
import SocketIO
import Combine
import CoreLocation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - PlayerLocation Model (누락된 모델 추가)
struct PlayerLocation: Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let level: Int
    let lastSeen: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

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
    private var locationThrottleTimer: Timer?
    private var lastPingTime: Date?
    private var connectionRetryCount = 0
    private let maxRetryCount = 5
    
    // ✅ 캐싱 및 최적화
    private var cachedPrices: [String: (price: Int, timestamp: Date)] = [:]
    private var lastLocationUpdate: Date?
    private let locationUpdateInterval: TimeInterval = 5.0 // 5초 간격
    
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
        // ✅ 메모리 누수 방지
        disconnect()
        invalidateAllTimers()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Connection Management
extension SocketManager {
    func connect(with token: String? = nil) {
        guard let url = URL(string: serverURL) else {
            print("❌ Invalid server URL")
            return
        }
        
        // ✅ 기존 연결 정리
        disconnect()
        
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
        
        // ✅ 모든 타이머 정리
        invalidateAllTimers()
        
        socket?.disconnect()
        socket = nil
        manager = nil
        
        connectionStatus = .disconnected
        isConnected = false
        
        print("🔌 Socket 연결 해제됨")
    }
    
    // ✅ 타이머 정리 메서드
    private func invalidateAllTimers() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        locationThrottleTimer?.invalidate()
        locationThrottleTimer = nil
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
        
        // ✅ 지수 백오프 적용
        let delay = min(Double(connectionRetryCount * connectionRetryCount), 30.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
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
        // ✅ 백그라운드에서는 연결을 유지하되 빈도를 줄임
        invalidateAllTimers()
        
        // 백그라운드 태스크 등록
        if isConnected {
            startBackgroundHeartbeat()
        }
    }
    
    @objc private func appWillEnterForeground() {
        // ✅ 포그라운드로 돌아올 때 연결 상태 확인
        if connectionStatus == .connected {
            startHeartbeat()
        } else if NetworkManager.shared.isAuthenticated {
            reconnect()
        }
    }
    
    // ✅ 백그라운드용 저빈도 하트비트
    private func startBackgroundHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
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
            DispatchQueue.main.async {
                self?.handleWelcome(data)
            }
        }
        
        socket.on("playerJoined") { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handlePlayerJoined(data)
            }
        }
        
        socket.on("playerLeft") { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handlePlayerLeft(data)
            }
        }
        
        // MARK: - Market Events
        socket.on("priceUpdate") { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handlePriceUpdate(data)
            }
        }
        
        socket.on("marketAlert") { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handleMarketAlert(data)
            }
        }
        
        // MARK: - Location Events
        socket.on("nearbyMerchants") { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handleNearbyMerchants(data)
            }
        }
        
        socket.on("playersInArea") { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handlePlayersInArea(data)
            }
        }
        
        // MARK: - Trade Events
        socket.on("tradeNotification") { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handleTradeNotification(data)
            }
        }
        
        // MARK: - System Events
        socket.on("systemMessage") { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handleSystemMessage(data)
            }
        }
        
        socket.on("pong") { [weak self] data, ack in
            self?.handlePong()
        }
        
        // ✅ 에러 이벤트 처리
        socket.on("error") { [weak self] data, ack in
            DispatchQueue.main.async {
                self?.handleServerError(data)
            }
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
        
        invalidateAllTimers()
        
        // ✅ 자동 재연결 시도 (인증된 사용자만)
        if NetworkManager.shared.isAuthenticated && connectionRetryCount < maxRetryCount {
            scheduleReconnect()
        }
    }
    
    private func handleError(_ data: [Any]) {
        print("❌ Socket 오류: \(data)")
        connectionStatus = .error
        
        if let errorData = data.first as? [String: Any],
           let message = errorData["message"] as? String {
            print("Socket 오류 메시지: \(message)")
            
            // ✅ 특정 오류에 대한 처리
            if message.contains("authentication") {
                // 인증 오류 시 로그아웃 처리
                DispatchQueue.main.async {
                    NetworkManager.shared.logout()
                }
            }
        }
    }
    
    private func handleServerError(_ data: [Any]) {
        if let errorData = data.first as? [String: Any],
           let message = errorData["message"] as? String {
            
            // ✅ 사용자에게 알림
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ServerError"),
                    object: nil,
                    userInfo: ["message": message]
                )
            }
        }
    }
    
    private func handleReconnection() {
        print("🔄 Socket 재연결 성공")
        connectionRetryCount = 0
    }
    
    // ✅ 누락된 이벤트 핸들러들 추가
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
            
            if !playersInArea.contains(where: { $0.id == player.id }) {
                playersInArea.append(player)
            }
        }
    }
    
    private func handlePlayerLeft(_ data: [Any]) {
        if let playerData = data.first as? [String: Any],
           let playerId = playerData["playerId"] as? String {
            
            playersInArea.removeAll { $0.id == playerId }
        }
    }
    
    private func handleMarketAlert(_ data: [Any]) {
        if let alertData = data.first as? [String: Any],
           let title = alertData["title"] as? String,
           let message = alertData["message"] as? String {
            
            let event = GameEvent(
                title: title,
                description: message,
                type: .specialEvent,
                timestamp: Date()
            )
            
            realTimeEvents.append(event)
            
            // 최대 10개 이벤트만 유지
            if realTimeEvents.count > 10 {
                realTimeEvents.removeFirst()
            }
        }
    }
    
    private func handlePlayersInArea(_ data: [Any]) {
        if let playersData = data.first as? [[String: Any]] {
            let players = playersData.compactMap { parsePlayerLocation(from: $0) }
            playersInArea = players
        }
    }
    
    private func handleTradeNotification(_ data: [Any]) {
        if let tradeData = data.first as? [String: Any],
           let playerName = tradeData["playerName"] as? String,
           let itemName = tradeData["itemName"] as? String,
           let action = tradeData["action"] as? String {
            
            let event = GameEvent(
                title: "거래 알림",
                description: "\(playerName)님이 \(itemName)을(를) \(action == "buy" ? "구매" : "판매")했습니다.",
                type: .priceChange,
                timestamp: Date()
            )
            
            realTimeEvents.append(event)
            
            if realTimeEvents.count > 10 {
                realTimeEvents.removeFirst()
            }
        }
    }
    
    private func handleSystemMessage(_ data: [Any]) {
        if let messageData = data.first as? [String: Any],
           let message = messageData["message"] as? String {
            
            let event = GameEvent(
                title: "시스템 메시지",
                description: message,
                type: .achievement,
                timestamp: Date()
            )
            
            realTimeEvents.append(event)
            
            if realTimeEvents.count > 10 {
                realTimeEvents.removeFirst()
            }
        }
    }
    
    private func handlePriceUpdate(_ data: [Any]) {
        guard let priceData = data.first as? [String: Any] else { return }
        
        var updates: [String: Int] = [:]
        let now = Date()
        
        for (key, value) in priceData {
            if let price = value as? Int {
                updates[key] = price
                // ✅ 캐시 업데이트
                cachedPrices[key] = (price: price, timestamp: now)
            }
        }
        
        priceUpdates = updates
    }
    
    private func handleNearbyMerchants(_ data: [Any]) {
        guard let merchantsData = data.first as? [[String: Any]] else { return }
        
        let merchants = merchantsData.compactMap { data -> Merchant? in
            return parseMerchant(from: data)
        }
        
        nearbyMerchants = merchants
    }
    
    private func scheduleReconnect() {
        let delay = min(Double(connectionRetryCount * 2), 10.0)
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.reconnect()
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func sendPing() {
        lastPingTime = Date()
        socket?.emit("ping")
    }
    
    private func handlePong() {
        if let pingTime = lastPingTime {
            let latency = Date().timeIntervalSince(pingTime)
            print("🏓 Ping: \(Int(latency * 1000))ms")
        }
    }
    
    private func requestInitialData() {
        // 초기 데이터 요청
        socket?.emit("requestInitialData")
    }
}

// MARK: - Public Methods
extension SocketManager {
    // ✅ 스로틀링이 적용된 위치 업데이트
    func updateLocation(_ location: CLLocationCoordinate2D) {
        guard isConnected else { return }
        
        let now = Date()
        if let lastUpdate = lastLocationUpdate,
           now.timeIntervalSince(lastUpdate) < locationUpdateInterval {
            return // 너무 빈번한 업데이트 방지
        }
        
        lastLocationUpdate = now
        
        socket?.emit("updateLocation", [
            "lat": location.latitude,
            "lng": location.longitude,
            "timestamp": Int(now.timeIntervalSince1970)
        ])
    }
    
    func joinRoom(_ roomId: String) {
        guard isConnected else { return }
        socket?.emit("joinRoom", roomId)
    }
    
    func leaveRoom(_ roomId: String) {
        guard isConnected else { return }
        socket?.emit("leaveRoom", roomId)
    }
    
    // ✅ 캐시된 가격 조회
    func getCachedPrice(for item: String) -> Int? {
        if let cached = cachedPrices[item],
           Date().timeIntervalSince(cached.timestamp) < 300 { // 5분 캐시
            return cached.price
        }
        return nil
    }
    
    // ✅ 거래 요청 전송 (GameManager에서 사용)
    func sendTradeRequest(merchantId: String, itemName: String, action: String) {
        guard isConnected else { return }
        
        socket?.emit("tradeRequest", [
            "merchantId": merchantId,
            "itemName": itemName,
            "action": action,
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
    }
}

// MARK: - Helper Methods
extension SocketManager {
    // ✅ 수정된 Merchant 파싱 (올바른 타입 사용)
    private func parseMerchant(from data: [String: Any]) -> Merchant? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let typeString = data["type"] as? String,
              let districtString = data["district"] as? String,
              let licenseValue = data["requiredLicense"] as? Int else {
            return nil
        }
        
        // ✅ 수정: Merchant.MerchantType → MerchantType
        guard let merchantType = MerchantType(rawValue: typeString),
              let district = SeoulDistrict(rawValue: districtString),
              let license = LicenseLevel(rawValue: licenseValue) else {
            return nil
        }
        
        let location = data["location"] as? [String: Double]
        let inventory = data["inventory"] as? [[String: Any]] ?? []
        let trustLevel = data["trustLevel"] as? Int ?? 0
        
        let coordinate = CLLocationCoordinate2D(
            latitude: location?["lat"] ?? 0,
            longitude: location?["lng"] ?? 0
        )
        
        // ✅ 수정: 누락된 매개변수들을 기본값으로 추가
            return Merchant(
                id: id,
                name: name,
                title: nil, // 기본값
                type: merchantType,
                personality: .friendly, // 기본값
                district: district,
                coordinate: coordinate,
                requiredLicense: license,
                appearanceId: 1, // 기본값
                portraitId: 1, // 기본값
                priceModifier: 1.0, // 기본값
                negotiationDifficulty: 3, // 기본값
                preferredItems: [], // 기본값
                dislikedItems: [], // 기본값
                reputationRequirement: 0, // 기본값
                friendshipLevel: 0, // 기본값
                inventory: parseMerchantInventory(inventory), // ✅ 수정: MerchantItem 반환
                trustLevel: trustLevel,
                isActive: true, // 기본값
                currentMood: .neutral, // 기본값
                lastRestocked: Date(), // 기본값
                specialAbilities: [], // 기본값
                isQuestGiver: false // 기본값
            )
        }
    // 2. ✅ 새로운 함수: MerchantItem을 파싱하는 함수
    private func parseMerchantInventory(_ inventoryData: [[String: Any]]) -> [MerchantItem] {
        return inventoryData.compactMap { itemData -> MerchantItem? in
            guard let itemId = itemData["item_id"] as? String ?? itemData["itemId"] as? String,
                  let name = itemData["name"] as? String,
                  let categoryString = itemData["category"] as? String,
                  let price = itemData["price"] as? Int else {
                return nil
            }
            
            // 카테고리 파싱
            let category = ItemCategory(rawValue: categoryString) ?? .modern
            
            // 희귀도 파싱
            let rarityInt = itemData["rarity"] as? Int ?? 1
            let rarity = ItemRarity(rawValue: rarityInt) ?? .common
            
            let stock = itemData["stock"] as? Int ?? 1
            
            return MerchantItem(
                id: UUID().uuidString,
                itemId: itemId,
                name: name,
                category: category,
                basePrice: price,
                currentPrice: price,
                rarity: rarity,
                stock: stock,
                maxStock: stock * 2,
                restockAmount: max(1, stock / 2) // ✅ 추가: 재입고 수량 (재고의 절반, 최소 1개)
            )
        }
    }
    
   
    
    // ✅ PlayerLocation 파싱 메서드 추가
    private func parsePlayerLocation(from data: [String: Any]) -> PlayerLocation? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double else {
            return nil
        }
        
        let level = data["level"] as? Int ?? 1
        let lastSeen = data["lastSeen"] as? String ?? ""
        
        return PlayerLocation(
            id: id,
            name: name,
            latitude: latitude,
            longitude: longitude,
            level: level,
            lastSeen: lastSeen
        )
    }
}

// MARK: - Connection Status Enum
enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case disconnecting
    case error
    case failed
}
