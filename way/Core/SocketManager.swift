// 📁 Core/SocketManager.swift - 수정된 버전
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
    private var locationThrottleTimer: Timer? // ✅ 위치 업데이트 스로틀링
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
        
        // ✅ 에러 이벤트 처리
        socket.on("error") { [weak self] data, ack in
            self?.handleServerError(data)
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
        
        DispatchQueue.main.async {
            self.priceUpdates = updates
        }
    }
    
    private func handleNearbyMerchants(_ data: [Any]) {
        guard let merchantsData = data.first as? [[String: Any]] else { return }
        
        let merchants = merchantsData.compactMap { data -> Merchant? in
            return parseMerchant(from: data)
        }
        
        DispatchQueue.main.async {
            self.nearbyMerchants = merchants
        }
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
}

// MARK: - Helper Methods
extension SocketManager {
    private func parseMerchant(from data: [String: Any]) -> Merchant? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let type = data["type"] as? String,
              let district = data["district"] as? String else {
            return nil
        }
        
        let location = data["location"] as? [String: Double]
        let inventory = data["inventory"] as? [[String: Any]] ?? []
        
        return Merchant(
            id: id,
            name: name,
            type: type,
            district: district,
            location: CLLocationCoordinate2D(
                latitude: location?["lat"] ?? 0,
                longitude: location?["lng"] ?? 0
            ),
            inventory: parseInventory(inventory),
            requiredLicense: data["requiredLicense"] as? Int ?? 1
        )
    }
    
    private func parseInventory(_ inventoryData: [[String: Any]]) -> [TradeItem] {
        return inventoryData.compactMap { itemData in
            guard let name = itemData["name"] as? String,
                  let category = itemData["category"] as? String,
                  let basePrice = itemData["basePrice"] as? Int else {
                return nil
            }
            
            return TradeItem(
                name: name,
                category: category,
                basePrice: basePrice,
                currentPrice: itemData["currentPrice"] as? Int ?? basePrice,
                grade: itemData["grade"] as? String ?? "common",
                requiredLicense: itemData["requiredLicense"] as? Int ?? 1,
                stock: itemData["stock"] as? Int ?? 0
            )
        }
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
