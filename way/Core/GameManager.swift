// 📁 Core/GameManager.swift - 정확한 모델 구조에 맞춘 수정 버전
import Foundation
import SwiftUI
import CoreLocation
import Combine

class GameManager: ObservableObject {
    // MARK: - Published Properties
    @Published var player = Player()
    @Published var skillEffectManager: SkillEffectManager? = nil
    @Published var merchants: [Merchant] = []
    @Published var availableItems: [TradeItem] = []
    @Published var priceBoard: [String: (district: SeoulDistrict, price: Int)] = [:]
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOnlineMode = false
    @Published var connectionStatus: String = "오프라인"
    @Published var realTimeEvents: [GameEvent] = []
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private let socketManager = SocketManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var itemResetTimer: Timer?
    private var locationUpdateTimer: Timer?
    private var currentLocation: CLLocationCoordinate2D?
    
    // MARK: - Game Statistics
    @Published var gameStats = GameStatistics()
    
    // MARK: - Initialization
    init() {
        setupInitialData()
        setupNetworkBindings()
        checkAuthenticationStatus()
        
        // 스킬 효과 매니저 초기화
        skillEffectManager = SkillEffectManager(player: player)
    }
    
    deinit {
        itemResetTimer?.invalidate()
        locationUpdateTimer?.invalidate()
    }
}

// MARK: - Initial Setup
extension GameManager {
    private func setupInitialData() {
        generateOfflineData()
    }
    
    private func checkAuthenticationStatus() {
        isAuthenticated = networkManager.isAuthenticated
        
        if isAuthenticated {
            Task {
                await attemptOnlineMode()
            }
        }
    }
    
    private func setupNetworkBindings() {
        socketManager.$isConnected
            .sink { [weak self] connected in
                DispatchQueue.main.async {
                    self?.updateConnectionStatus(connected)
                }
            }
            .store(in: &cancellables)
        
        socketManager.$priceUpdates
            .sink { [weak self] updates in
                DispatchQueue.main.async {
                    self?.applyPriceUpdates(updates)
                }
            }
            .store(in: &cancellables)
        
        socketManager.$nearbyMerchants
            .sink { [weak self] merchants in
                DispatchQueue.main.async {
                    if !merchants.isEmpty {
                        self?.updateNearbyMerchants(merchants)
                    }
                }
            }
            .store(in: &cancellables)
        
        socketManager.$realTimeEvents
            .sink { [weak self] events in
                DispatchQueue.main.async {
                    self?.realTimeEvents = events
                }
            }
            .store(in: &cancellables)
        
        socketManager.$connectionStatus
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    self?.updateConnectionStatusText(status)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateConnectionStatus(_ connected: Bool) {
        if connected && isAuthenticated {
            isOnlineMode = true
            connectionStatus = "온라인"
            startLocationUpdates()
            requestInitialOnlineData()
        } else {
            isOnlineMode = false
            connectionStatus = isAuthenticated ? "연결 중..." : "오프라인"
            locationUpdateTimer?.invalidate()
        }
    }
    
    private func updateConnectionStatusText(_ status: ConnectionStatus) {
        switch status {
        case .connected:
            connectionStatus = "온라인"
        case .connecting:
            connectionStatus = "연결 중..."
        case .disconnected:
            connectionStatus = isAuthenticated ? "연결 끊김" : "오프라인"
        case .error, .failed:
            connectionStatus = "연결 오류"
        case .disconnecting:
            connectionStatus = "연결 해제 중..."
        case .reconnecting:
            connectionStatus = "재연결 중..."  // 실행 구문 추가

        }
    }
}

// MARK: - Authentication
extension GameManager {
    func login(email: String, password: String) async {
        await setLoading(true)
        clearError()
        
        do {
            let response = try await networkManager.login(email: email, password: password)
            
            if response.success {
                await handleSuccessfulLogin(response)
                await attemptOnlineMode()
            } else {
                await setError(response.error ?? "로그인 실패")
            }
        } catch {
            await handleLoginError(error)
        }
        
        await setLoading(false)
    }
    
    func register(email: String, password: String, playerName: String) async {
        await setLoading(true)
        clearError()
        
        do {
            let response = try await networkManager.register(
                email: email,
                password: password,
                playerName: playerName
            )
            
            if response.success {
                await login(email: email, password: password)
            } else {
                await setError(response.error ?? "회원가입 실패")
            }
        } catch {
            await setError(error.localizedDescription)
        }
        
        await setLoading(false)
    }
    
    func logout() {
        socketManager.disconnect()
        networkManager.logout()
        
        isAuthenticated = false
        isOnlineMode = false
        connectionStatus = "오프라인"
        player = Player()
        realTimeEvents.removeAll()
        
        generateOfflineData()
        locationUpdateTimer?.invalidate()
    }
    
    private func attemptOnlineMode() async {
        guard isAuthenticated else { return }
        
        do {
            if let token = UserDefaults.standard.string(forKey: "auth_token") {
                socketManager.connect(with: token)
            }
            await loadOnlineGameData()
        } catch {
            print("온라인 모드 진입 실패: \(error)")
            await setError("서버 연결에 실패했습니다. 오프라인 모드로 진행합니다.")
        }
    }
    
    private func handleSuccessfulLogin(_ response: AuthResponse) async {
        await MainActor.run {
            self.isAuthenticated = true
            
            if let playerInfo = response.player {
                self.updatePlayerFromResponse(playerInfo)
            }
        }
    }
    
    private func handleLoginError(_ error: Error) async {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.isOnlineMode = false
            self.connectionStatus = "오프라인"
        }
    }
    
    private func updatePlayerFromResponse(_ playerInfo: PlayerInfo) {
        player.name = playerInfo.name
        player.money = playerInfo.money
        player.trustPoints = playerInfo.trustPoints
        player.currentLicense = LicenseLevel(rawValue: playerInfo.currentLicense) ?? .beginner
        player.maxInventorySize = playerInfo.maxInventorySize
        
        gameStats.level = calculateLevel(from: playerInfo.trustPoints)
        gameStats.experience = playerInfo.trustPoints
    }
}

// MARK: - Online Data Management
extension GameManager {
    private func loadOnlineGameData() async {
        guard isAuthenticated else { return }
        
        async let playerData = loadPlayerData()
        async let marketData = loadMarketData()
        async let merchantData = loadMerchantData()
        
        let (_, _, _) = await (playerData, marketData, merchantData)
    }
    
    private func loadPlayerData() async {
        do {
            let response = try await networkManager.getPlayerData()
            if let data = response.data {
                await MainActor.run {
                    self.updateDetailedPlayerData(data)
                }
            }
        } catch {
            print("플레이어 데이터 로드 실패: \(error)")
        }
    }
    
    private func loadMarketData() async {
        do {
            let response = try await networkManager.getMarketPrices()
            if let prices = response.data {
                await MainActor.run {
                    self.updateMarketPrices(prices)
                }
            }
        } catch {
            print("시장 데이터 로드 실패: \(error)")
        }
    }
    
    private func loadMerchantData() async {
        do {
            let response = try await networkManager.getMerchants()
            if let merchants = response.data {
                await MainActor.run {
                    self.updateMerchants(merchants)
                }
            }
        } catch {
            print("상인 데이터 로드 실패: \(error)")
        }
    }
    
    private func requestInitialOnlineData() {
        if let location = currentLocation {
            socketManager.updateLocation(location)
        }
    }
}

// MARK: - Data Update Methods
extension GameManager {
    private func updateDetailedPlayerData(_ data: PlayerDetail) {
        player.name = data.name
        player.money = data.money
        player.trustPoints = data.trustPoints
        player.currentLicense = LicenseLevel(rawValue: data.currentLicense) ?? .beginner
        player.maxInventorySize = data.maxInventorySize
        
        // ✅ TradeItem 생성자 정확한 순서: itemId, name, category, grade, requiredLicense, basePrice, currentPrice
        player.inventory = data.inventory.map { item in
            TradeItem(
                itemId: item.id ?? UUID().uuidString,
                name: item.name,
                category: item.category,
                grade: ItemGrade(rawValue: item.grade) ?? .common,
                requiredLicense: LicenseLevel(rawValue: item.requiredLicense) ?? .beginner,
                basePrice: item.basePrice,
                currentPrice: item.currentPrice
            )
        }
        
        currentLocation = CLLocationCoordinate2D(
            latitude: data.location.lat,
            longitude: data.location.lng
        )
    }
    
    private func updateMarketPrices(_ prices: [MarketPrice]) {
        var newPriceBoard: [String: (district: SeoulDistrict, price: Int)] = [:]
        
        for price in prices {
            let randomDistrict = SeoulDistrict.allCases.randomElement() ?? .gangnam
            newPriceBoard[price.itemName] = (district: randomDistrict, price: price.currentPrice)
        }
        
        priceBoard = newPriceBoard
    }
    
    private func updateMerchants(_ merchantData: [MerchantData]) {
        merchants = merchantData.compactMap { data in
            // ✅ 정확한 enum 변환 확인
            guard let merchantType = MerchantType(rawValue: data.type),
                  let district = SeoulDistrict(rawValue: data.district),
                  let license = LicenseLevel(rawValue: data.requiredLicense) else {
                return nil
            }
            
            // ✅ Merchant 생성자 정확한 순서: name, type, district, coordinate, requiredLicense, inventory, trustLevel
            return Merchant(
                name: data.name,
                type: merchantType,
                district: district,
                coordinate: CLLocationCoordinate2D(
                    latitude: data.location.lat,
                    longitude: data.location.lng
                ),
                requiredLicense: license,
                inventory: data.inventory,
                trustLevel: 0
            )
        }
    }
    
    private func applyPriceUpdates(_ updates: [String: Int]) {
        for (itemName, newPrice) in updates {
            if let existingItem = priceBoard[itemName] {
                priceBoard[itemName] = (district: existingItem.district, price: newPrice)
            }
        }
    }
    
    private func updateNearbyMerchants(_ nearbyMerchants: [Merchant]) {
        var updatedMerchants = merchants
        
        for nearbyMerchant in nearbyMerchants {
            if let index = updatedMerchants.firstIndex(where: { $0.id == nearbyMerchant.id }) {
                updatedMerchants[index] = nearbyMerchant
            } else {
                updatedMerchants.append(nearbyMerchant)
            }
        }
        
        merchants = updatedMerchants
    }
}

// MARK: - Location Management
extension GameManager {
    private func startLocationUpdates() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateLocationToServer()
        }
    }
    
    private func updateLocationToServer() {
        guard isOnlineMode, let location = currentLocation else { return }
        socketManager.updateLocation(location)
    }
    
    func updatePlayerLocation(_ location: CLLocationCoordinate2D) {
        currentLocation = location
        
        if isOnlineMode {
            socketManager.updateLocation(location)
        }
    }
}

// MARK: - Trading Functions
extension GameManager {
    func buyItem(_ item: TradeItem, from merchant: Merchant) async -> Bool {
        if isOnlineMode {
            return await buyItemOnline(item, from: merchant)
        } else {
            return buyItemOffline(item, from: merchant)
        }
    }
    
    func sellItem(_ item: TradeItem, to merchant: Merchant, at location: CLLocationCoordinate2D) async -> Bool {
        if isOnlineMode {
            return await sellItemOnline(item, to: merchant)
        } else {
            return sellItemOffline(item, to: merchant, at: location)
        }
    }
    
    private func buyItemOnline(_ item: TradeItem, from merchant: Merchant) async -> Bool {
        do {
            let response = try await networkManager.buyItem(
                merchantId: merchant.id,
                itemName: item.name
            )
            
            if response.success, let data = response.data {
                await updatePlayerAfterPurchase(data)
                await updateGameStatistics(profit: 0, trade: true)
                return true
            } else {
                await setError(response.error ?? "구매 실패")
                return false
            }
        } catch {
            await setError(error.localizedDescription)
            return false
        }
    }
    
    private func sellItemOnline(_ item: TradeItem, to merchant: Merchant) async -> Bool {
        guard let inventoryItem = player.inventory.first(where: { $0.name == item.name }) else {
            await setError("인벤토리에서 아이템을 찾을 수 없습니다.")
            return false
        }
        
        do {
            let response = try await networkManager.sellItem(
                itemId: inventoryItem.id,
                merchantId: merchant.id
            )
            
            if response.success, let data = response.data {
                await updatePlayerAfterSale(data)
                await updateGameStatistics(profit: data.soldItem?.sellPrice ?? 0, trade: true)
                return true
            } else {
                await setError(response.error ?? "판매 실패")
                return false
            }
        } catch {
            await setError(error.localizedDescription)
            return false
        }
    }
    
    private func buyItemOffline(_ item: TradeItem, from merchant: Merchant) -> Bool {
        guard player.money >= item.currentPrice else {
            errorMessage = "돈이 부족합니다."
            return false
        }
        
        guard player.inventory.count < player.maxInventorySize else {
            errorMessage = "인벤토리가 가득 찼습니다."
            return false
        }
        
        player.money -= item.currentPrice
        player.inventory.append(item)
        player.trustPoints += 1
        
        Task {
            await updateGameStatistics(profit: 0, trade: true)
        }
        
        return true
    }
    
    private func sellItemOffline(_ item: TradeItem, to merchant: Merchant, at location: CLLocationCoordinate2D) -> Bool {
        guard let index = player.inventory.firstIndex(where: { $0.name == item.name }) else {
            errorMessage = "인벤토리에서 아이템을 찾을 수 없습니다."
            return false
        }
        
        let sellPrice = Int(Double(item.currentPrice) * (0.7 + Double.random(in: 0...0.2)))
        let profit = sellPrice - item.basePrice
        
        player.inventory.remove(at: index)
        player.money += sellPrice
        player.trustPoints += 2
        
        Task {
            await updateGameStatistics(profit: profit, trade: true)
        }
        
        return true
    }
    
    private func updatePlayerAfterPurchase(_ data: TradeResult) async {
        await MainActor.run {
            self.player.money = data.newMoney
            self.player.trustPoints = data.newTrustPoints
            
            if let purchasedItem = data.purchasedItem {
                // ✅ TradeItem 생성자 정확한 순서
                let newItem = TradeItem(
                    itemId: purchasedItem.id ?? UUID().uuidString,
                    name: purchasedItem.name,
                    category: purchasedItem.category,
                    grade: ItemGrade(rawValue: purchasedItem.grade) ?? .common,
                    requiredLicense: .beginner,
                    basePrice: purchasedItem.purchasePrice,
                    currentPrice: purchasedItem.purchasePrice
                )
                self.player.inventory.append(newItem)
            }
        }
    }
    
    private func updatePlayerAfterSale(_ data: TradeResult) async {
        await MainActor.run {
            self.player.money = data.newMoney
            self.player.trustPoints = data.newTrustPoints
            
            if let soldItem = data.soldItem {
                self.player.inventory.removeAll { $0.name == soldItem.name }
            }
        }
    }
}

// MARK: - Offline Data Generation
extension GameManager {
    private func generateOfflineData() {
        generateOfflineMerchants()
        generateOfflineItems()
        generateOfflinePriceBoard()
        setupItemResetTimer()
    }
    
    private func generateOfflineMerchants() {
        merchants = [
            // ✅ 정확한 enum 값 사용
            Merchant(
                name: "강남 전자상가",
                type: .retail,  // ✅ 실제 존재하는 enum 값
                district: .gangnam,  // ✅ 실제 존재하는 enum 값
                coordinate: CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276),
                requiredLicense: .beginner,
                inventory: generateElectronicsItems(),
                trustLevel: 0
            ),
            Merchant(
                name: "명동 면세점",
                type: .wholesale,  // ✅ 실제 존재하는 enum 값
                district: .myeongdong,  // ✅ 실제 존재하는 enum 값
                coordinate: CLLocationCoordinate2D(latitude: 37.5636, longitude: 126.9820),
                requiredLicense: .intermediate,
                inventory: generateLuxuryItems(),
                trustLevel: 0
            ),
            Merchant(
                name: "홍대 트렌드샵",
                type: .premium,  // ✅ 실제 존재하는 enum 값
                district: .hongdae,  // ✅ 실제 존재하는 enum 값
                coordinate: CLLocationCoordinate2D(latitude: 37.5563, longitude: 126.9234),
                requiredLicense: .beginner,
                inventory: generateFashionItems(),
                trustLevel: 0
            )
        ]
    }
    
    private func generateOfflineItems() {
        availableItems = generateElectronicsItems() + generateLuxuryItems() + generateFashionItems()
    }
    
    private func generateOfflinePriceBoard() {
        priceBoard = [
            "iPhone 15 Pro": (district: .gangnam, price: 1200000),
            "MacBook Pro": (district: .gangnam, price: 2500000),
            "Louis Vuitton 가방": (district: .myeongdong, price: 3000000),  // ✅ 정확한 enum 값
            "Rolex 시계": (district: .myeongdong, price: 15000000),
            "Nike 에어맥스": (district: .hongdae, price: 300000),  // ✅ 정확한 enum 값
            "디자이너 청바지": (district: .hongdae, price: 400000)
        ]
    }
    
    private func setupItemResetTimer() {
        itemResetTimer?.invalidate()
        itemResetTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.refreshOfflineData()
        }
    }
    
    private func refreshOfflineData() {
        generateOfflineItems()
        updatePriceBoard()
    }
    
    private func updatePriceBoard() {
        for (item, info) in priceBoard {
            let variation = Double.random(in: 0.8...1.2)
            let newPrice = Int(Double(info.price) * variation)
            priceBoard[item] = (district: info.district, price: newPrice)
        }
    }
}

// MARK: - Item Generation Methods
extension GameManager {
    private func generateElectronicsItems() -> [TradeItem] {
        return [
            // ✅ TradeItem 생성자 정확한 순서 (itemId 추가)
            TradeItem(itemId: "iphone_15_pro", name: "iPhone 15 Pro", category: "IT부품", grade: .rare, requiredLicense: .intermediate, basePrice: 1200000, currentPrice: randomPrice(base: 1200000)),
            TradeItem(itemId: "macbook_pro", name: "MacBook Pro", category: "IT부품", grade: .rare, requiredLicense: .intermediate, basePrice: 2500000, currentPrice: randomPrice(base: 2500000)),
            TradeItem(itemId: "galaxy_s24", name: "Galaxy S24", category: "IT부품", grade: .intermediate, requiredLicense: .beginner, basePrice: 1000000, currentPrice: randomPrice(base: 1000000)),
            TradeItem(itemId: "ipad_air", name: "iPad Air", category: "IT부품", grade: .intermediate, requiredLicense: .beginner, basePrice: 800000, currentPrice: randomPrice(base: 800000))
        ]
    }
    
    private func generateLuxuryItems() -> [TradeItem] {
        return [
            TradeItem(itemId: "lv_bag", name: "Louis Vuitton 가방", category: "명품", grade: .legendary, requiredLicense: .advanced, basePrice: 3000000, currentPrice: randomPrice(base: 3000000)),
            TradeItem(itemId: "rolex_watch", name: "Rolex 시계", category: "명품", grade: .legendary, requiredLicense: .advanced, basePrice: 15000000, currentPrice: randomPrice(base: 15000000)),
            TradeItem(itemId: "hermes_scarf", name: "Hermes 스카프", category: "명품", grade: .rare, requiredLicense: .intermediate, basePrice: 500000, currentPrice: randomPrice(base: 500000))
        ]
    }
    
    private func generateFashionItems() -> [TradeItem] {
        return [
            TradeItem(itemId: "nike_airmax", name: "Nike 에어맥스", category: "의류", grade: .common, requiredLicense: .beginner, basePrice: 300000, currentPrice: randomPrice(base: 300000)),
            TradeItem(itemId: "designer_jeans", name: "디자이너 청바지", category: "의류", grade: .common, requiredLicense: .beginner, basePrice: 400000, currentPrice: randomPrice(base: 400000)),
            TradeItem(itemId: "limited_hoodie", name: "한정판 후드티", category: "의류", grade: .intermediate, requiredLicense: .beginner, basePrice: 250000, currentPrice: randomPrice(base: 250000))
        ]
    }
    
    private func randomPrice(base: Int) -> Int {
        let variation = Double.random(in: 0.8...1.2)
        return Int(Double(base) * variation)
    }
}

// MARK: - Game Statistics
extension GameManager {
    private func updateGameStatistics(profit: Int, trade: Bool) async {
        await MainActor.run {
            if trade {
                self.gameStats.totalTrades += 1
            }
            
            if profit > 0 {
                self.gameStats.totalProfit += profit
            }
            
            self.gameStats.level = self.calculateLevel(from: self.player.trustPoints)
            self.gameStats.experience = self.player.trustPoints
        }
    }
    
    private func calculateLevel(from trustPoints: Int) -> Int {
        return max(1, trustPoints / 100 + 1)
    }
}

// MARK: - Utility Methods
extension GameManager {
    @MainActor
    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    @MainActor
    private func setError(_ error: String) {
        errorMessage = error
    }
    
    private func clearError() {
        DispatchQueue.main.async {
            self.errorMessage = nil
        }
    }
}

// MARK: - Game Statistics Model
struct GameStatistics {
    var level: Int = 1
    var experience: Int = 0
    var totalTrades: Int = 0
    var totalProfit: Int = 0
    var playTime: TimeInterval = 0
}

// MARK: - Game Event Model
struct GameEvent: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let type: EventType
    let timestamp: Date
    
    enum EventType: String, Codable {
        case priceChange = "price_change"
        case newMerchant = "new_merchant"
        case specialEvent = "special_event"
        case achievement = "achievement"
    }
}
