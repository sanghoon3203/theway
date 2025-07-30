// 📁 Core/GameManager.swift
import Foundation
import SwiftUI
import CoreLocation
import Combine

class GameManager: ObservableObject {
    // MARK: - Published Properties
    @Published var player = Player()
    @Published var merchants: [Merchant] = []
    @Published var availableItems: [TradeItem] = []
    @Published var priceBoard: [String: (district: SeoulDistrict, price: Int)] = [:]
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let networkManager = NetworkManager.shared
    private let socketManager = SocketManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var itemResetTimer: Timer?
    private var isOnlineMode = false
    
    // MARK: - Initialization
    init() {
        setupInitialData()
        setupNetworkBindings()
        startItemResetTimer()
    }
    
    deinit {
        itemResetTimer?.invalidate()
    }
}

// MARK: - Initial Setup
extension GameManager {
    private func setupInitialData() {
        generateTradeItems()
        generateMerchants()
        updatePriceBoard()
    }
    
    private func setupNetworkBindings() {
        // Socket 연결 상태 관찰
        socketManager.$isConnected
            .sink { [weak self] connected in
                print("Socket 연결 상태: \(connected)")
                if connected {
                    self?.sendCurrentLocation()
                }
            }
            .store(in: &cancellables)
        
        // 실시간 가격 업데이트 관찰
        socketManager.$priceUpdates
            .sink { [weak self] updates in
                self?.applyPriceUpdates(updates)
            }
            .store(in: &cancellables)
        
        // 주변 상인 업데이트 관찰
        socketManager.$nearbyMerchants
            .sink { [weak self] merchants in
                if !merchants.isEmpty {
                    self?.updateNearbyMerchants(merchants)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Authentication
extension GameManager {
    func login(email: String, password: String) async {
        await setLoading(true)
        
        do {
            let response = try await networkManager.login(email: email, password: password)
            
            if response.success {
                await handleSuccessfulLogin(response)
                socketManager.connect()
                await loadGameData()
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
        networkManager.clearToken()
        
        isAuthenticated = false
        isOnlineMode = false
        player = Player()
        
        setupInitialData()
    }
    
    // MARK: - Authentication Helpers
    private func handleSuccessfulLogin(_ response: LoginResponse) async {
        await MainActor.run {
            self.isAuthenticated = true
            self.isOnlineMode = true
            
            if let playerInfo = response.player {
                self.updatePlayerFromResponse(playerInfo)
            }
        }
    }
    
    private func handleLoginError(_ error: Error) async {
        await MainActor.run {
            self.errorMessage = error.localizedDescription
            self.isOnlineMode = false
        }
    }
    
    private func updatePlayerFromResponse(_ playerInfo: PlayerInfo) {
        player.name = playerInfo.name
        player.money = playerInfo.money
        player.trustPoints = playerInfo.trustPoints
        player.currentLicense = LicenseLevel(rawValue: playerInfo.currentLicense) ?? .beginner
        player.maxInventorySize = playerInfo.maxInventorySize
    }
}

// MARK: - Game Data Management
extension GameManager {
    private func loadGameData() async {
        do {
            async let playerData = loadPlayerData()
            async let marketPrices = loadMarketPrices()
            async let merchantData = loadMerchantData()
            
            let (_, _, _) = await (playerData, marketPrices, merchantData)
        } catch {
            print("게임 데이터 로드 실패: \(error)")
        }
    }
    
    private func loadPlayerData() async {
        do {
            let response = try await networkManager.getPlayerData()
            if let data = response.data {
                await MainActor.run {
                    self.updatePlayerData(data)
                }
            }
        } catch {
            print("플레이어 데이터 로드 실패: \(error)")
        }
    }
    
    private func loadMarketPrices() async {
        do {
            let response = try await networkManager.getMarketPrices()
            if let prices = response.data {
                await MainActor.run {
                    self.updateMarketPrices(prices)
                }
            }
        } catch {
            print("시장 가격 로드 실패: \(error)")
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
}

// MARK: - Data Update Methods
extension GameManager {
    private func updatePlayerData(_ data: PlayerDetail) {
        player.money = data.money
        player.trustPoints = data.trustPoints
        player.currentLicense = LicenseLevel(rawValue: data.currentLicense) ?? .beginner
        player.maxInventorySize = data.maxInventorySize
        
        player.inventory = data.inventory.map { item in
            TradeItem(
                name: item.name,
                category: item.category,
                basePrice: item.basePrice,
                grade: ItemGrade(rawValue: item.grade) ?? .common,
                requiredLicense: LicenseLevel(rawValue: item.requiredLicense) ?? .beginner,
                currentPrice: item.currentPrice
            )
        }
    }
    
    private func updateMarketPrices(_ prices: [MarketPrice]) {
        var newPriceBoard: [String: (district: SeoulDistrict, price: Int)] = [:]
        
        for price in prices {
            if let district = SeoulDistrict(rawValue: price.district) {
                newPriceBoard[price.itemName] = (district: district, price: price.currentPrice)
            }
        }
        
        priceBoard = newPriceBoard
    }
    
    private func updateMerchants(_ merchantData: [MerchantData]) {
        merchants = merchantData.compactMap { data in
            createMerchant(from: data)
        }
    }
    
    private func createMerchant(from data: MerchantData) -> Merchant? {
        guard let type = Merchant.MerchantType(rawValue: data.type),
              let district = SeoulDistrict(rawValue: data.district),
              let license = LicenseLevel(rawValue: data.requiredLicense) else {
            return nil
        }
        
        let inventory = data.inventory.map { item in
            TradeItem(
                name: item.name,
                category: item.category,
                basePrice: item.price,
                grade: ItemGrade(rawValue: item.grade) ?? .common,
                requiredLicense: license,
                currentPrice: item.price
            )
        }
        
        return Merchant(
            name: data.name,
            type: type,
            district: district,
            coordinate: CLLocationCoordinate2D(
                latitude: data.location.lat,
                longitude: data.location.lng
            ),
            requiredLicense: license,
            inventory: inventory
        )
    }
}

// MARK: - Real-time Updates
extension GameManager {
    private func applyPriceUpdates(_ updates: [String: Int]) {
        updatePriceBoardWith(updates)
        updateMerchantInventoryPrices(updates)
    }
    
    private func updatePriceBoardWith(_ updates: [String: Int]) {
        for (itemName, newPrice) in updates {
            if var boardEntry = priceBoard[itemName] {
                boardEntry.price = newPrice
                priceBoard[itemName] = boardEntry
            }
        }
    }
    
    private func updateMerchantInventoryPrices(_ updates: [String: Int]) {
        for (itemName, newPrice) in updates {
            for i in merchants.indices {
                for j in merchants[i].inventory.indices {
                    if merchants[i].inventory[j].name == itemName {
                        merchants[i].inventory[j].currentPrice = newPrice
                    }
                }
            }
        }
    }
    
    private func updateNearbyMerchants(_ nearbyMerchants: [Merchant]) {
        self.merchants = nearbyMerchants
    }
    
    private func sendCurrentLocation() {
        let testLocation = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        socketManager.sendLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)
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
    
    // MARK: - Online Trading
    private func buyItemOnline(_ item: TradeItem, from merchant: Merchant) async -> Bool {
        do {
            let response = try await networkManager.buyItem(
                merchantId: merchant.id,
                itemName: item.name
            )
            
            if response.success, let data = response.data {
                await updatePlayerAfterPurchase(data)
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
        guard let itemId = player.inventory.first(where: { $0.name == item.name })?.id.uuidString else {
            return false
        }
        
        do {
            let response = try await networkManager.sellItem(
                itemId: itemId,
                merchantId: merchant.id
            )
            
            if response.success, let data = response.data {
                await updatePlayerAfterSale(data, itemId: itemId)
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
    
    // MARK: - Offline Trading
    private func buyItemOffline(_ item: TradeItem, from merchant: Merchant) -> Bool {
        guard canBuyItem(item) else { return false }
        
        player.money -= item.currentPrice
        player.inventory.append(item)
        player.trustPoints += 1
        
        return true
    }
    
    private func sellItemOffline(_ item: TradeItem, to merchant: Merchant, at location: CLLocationCoordinate2D) -> Bool {
        guard let index = player.inventory.firstIndex(where: { $0.id == item.id }) else {
            return false
        }
        
        let finalPrice = calculateSalePrice(item, merchantLocation: merchant.coordinate, playerLocation: location)
        
        player.money += finalPrice
        player.inventory.remove(at: index)
        player.trustPoints += 2
        
        return true
    }
    
    // MARK: - Trading Helpers
    private func canBuyItem(_ item: TradeItem) -> Bool {
        return player.money >= item.currentPrice &&
               player.inventory.count < player.maxInventorySize &&
               player.currentLicense.rawValue >= item.requiredLicense.rawValue
    }
    
    private func calculateSalePrice(_ item: TradeItem, merchantLocation: CLLocationCoordinate2D, playerLocation: CLLocationCoordinate2D) -> Int {
        let distance = calculateDistance(from: playerLocation, to: merchantLocation)
        let distanceBonus = min(distance / 1000 * 0.1, 0.5)
        return Int(Double(item.currentPrice) * (1.0 + distanceBonus))
    }
    
    private func updatePlayerAfterPurchase(_ data: PurchaseResponse) async {
        await MainActor.run {
            self.player.money = data.newMoney
            self.player.trustPoints = data.newTrustPoints
            
            if let acquiredItem = data.acquiredItem {
                let newItem = TradeItem(
                    name: acquiredItem.name,
                    category: acquiredItem.category,
                    basePrice: acquiredItem.price,
                    grade: ItemGrade(rawValue: acquiredItem.grade) ?? .common,
                    requiredLicense: LicenseLevel(rawValue: acquiredItem.requiredLicense) ?? .beginner,
                    currentPrice: acquiredItem.price
                )
                self.player.inventory.append(newItem)
            }
        }
    }
    
    private func updatePlayerAfterSale(_ data: SaleResponse, itemId: String) async {
        await MainActor.run {
            self.player.money = data.newMoney
            self.player.trustPoints = data.newTrustPoints
            
            if let index = self.player.inventory.firstIndex(where: { $0.id.uuidString == itemId }) {
                self.player.inventory.remove(at: index)
            }
        }
    }
}

// MARK: - Item and Merchant Generation
extension GameManager {
    private func generateTradeItems() {
        let categories = ["IT부품", "명품", "예술품", "화장품", "서적", "생활용품"]
        
        availableItems = categories.flatMap { category in
            ItemGrade.allCases.map { grade in
                TradeItem(
                    name: "\(category) (\(grade.rawValue))",
                    category: category,
                    basePrice: basePrice(for: grade),
                    grade: grade,
                    requiredLicense: requiredLicense(for: grade),
                    currentPrice: basePrice(for: grade)
                )
            }
        }
    }
    
    private func generateMerchants() {
        merchants = SeoulDistrict.allCases.flatMap { district in
            Merchant.MerchantType.allCases.map { merchantType in
                Merchant(
                    name: "\(district.rawValue) \(merchantType.rawValue)",
                    type: merchantType,
                    district: district,
                    coordinate: randomCoordinate(for: district),
                    requiredLicense: requiredLicense(for: merchantType),
                    inventory: generateMerchantInventory(for: merchantType)
                )
            }
        }
    }
    
    private func generateMerchantInventory(for type: Merchant.MerchantType) -> [TradeItem] {
        return availableItems
            .filter { $0.grade.rawValue <= type.maxItemGrade.rawValue }
            .shuffled()
            .prefix(Int.random(in: 3...8))
            .map { $0 }
    }
}

// MARK: - Price System
extension GameManager {
    private func updatePriceBoard() {
        var board: [String: (district: SeoulDistrict, price: Int)] = [:]
        
        for item in availableItems {
            let (bestDistrict, bestPrice) = findBestPriceForItem(item)
            board[item.name] = (district: bestDistrict, price: bestPrice)
        }
        
        priceBoard = board
    }
    
    private func findBestPriceForItem(_ item: TradeItem) -> (SeoulDistrict, Int) {
        var bestPrice = 0
        var bestDistrict = SeoulDistrict.gangnam
        
        for district in SeoulDistrict.allCases {
            var tempItem = item
            tempItem.updatePrice(for: district)
            
            if tempItem.currentPrice > bestPrice {
                bestPrice = tempItem.currentPrice
                bestDistrict = district
            }
        }
        
        return (bestDistrict, bestPrice)
    }
    
    private func startItemResetTimer() {
        itemResetTimer = Timer.scheduledTimer(withTimeInterval: 3 * 60 * 60, repeats: true) { _ in
            self.resetItemPrices()
        }
    }
    
    private func resetItemPrices() {
        // 아이템 가격 리셋
        for i in availableItems.indices {
            availableItems[i].demandMultiplier = Double.random(in: 0.5...2.0)
            availableItems[i].lastReset = Date()
        }
        
        // 상인 인벤토리 리셋
        for i in merchants.indices {
            merchants[i].inventory = generateMerchantInventory(for: merchants[i].type)
        }
        
        updatePriceBoard()
    }
}

// MARK: - Helper Methods
extension GameManager {
    private func basePrice(for grade: ItemGrade) -> Int {
        switch grade {
        case .common: return Int.random(in: 1000...5000)
        case .intermediate: return Int.random(in: 5000...15000)
        case .advanced: return Int.random(in: 15000...50000)
        case .rare: return Int.random(in: 50000...150000)
        case .legendary: return Int.random(in: 150000...500000)
        }
    }
    
    private func requiredLicense(for grade: ItemGrade) -> LicenseLevel {
        switch grade {
        case .common: return .beginner
        case .intermediate: return .intermediate
        case .advanced: return .advanced
        case .rare: return .expert
        case .legendary: return .master
        }
    }
    
    private func requiredLicense(for merchantType: Merchant.MerchantType) -> LicenseLevel {
        switch merchantType {
        case .retail: return .beginner
        case .wholesale: return .intermediate
        case .premium: return .advanced
        }
    }
    
    private func randomCoordinate(for district: SeoulDistrict) -> CLLocationCoordinate2D {
        let baseLatitude = 37.5665
        let baseLongitude = 126.9780
        
        return CLLocationCoordinate2D(
            latitude: baseLatitude + Double.random(in: -0.05...0.05),
            longitude: baseLongitude + Double.random(in: -0.05...0.05)
        )
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let location2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return location1.distance(from: location2)
    }
    
    // MARK: - UI Helper Methods
    @MainActor
    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    @MainActor
    private func setError(_ message: String) {
        errorMessage = message
    }
}
