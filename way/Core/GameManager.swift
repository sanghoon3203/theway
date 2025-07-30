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
    }
    
    deinit {
        itemResetTimer?.invalidate()
        locationUpdateTimer?.invalidate()
    }
}

// MARK: - Initial Setup
extension GameManager {
    private func setupInitialData() {
        // 오프라인 모드를 위한 기본 데이터 생성
        generateOfflineData()
    }
    
    private func checkAuthenticationStatus() {
        isAuthenticated = networkManager.isAuthenticated
        
        if isAuthenticated {
            // 인증된 상태면 자동으로 온라인 모드 시도
            Task {
                await attemptOnlineMode()
            }
        }
    }
    
    private func setupNetworkBindings() {
        // Socket 연결 상태 관찰
        socketManager.$isConnected
            .sink { [weak self] connected in
                DispatchQueue.main.async {
                    self?.updateConnectionStatus(connected)
                }
            }
            .store(in: &cancellables)
        
        // 실시간 가격 업데이트 관찰
        socketManager.$priceUpdates
            .sink { [weak self] updates in
                DispatchQueue.main.async {
                    self?.applyPriceUpdates(updates)
                }
            }
            .store(in: &cancellables)
        
        // 주변 상인 업데이트 관찰
        socketManager.$nearbyMerchants
            .sink { [weak self] merchants in
                DispatchQueue.main.async {
                    if !merchants.isEmpty {
                        self?.updateNearbyMerchants(merchants)
                    }
                }
            }
            .store(in: &cancellables)
        
        // 실시간 이벤트 관찰
        socketManager.$realTimeEvents
            .sink { [weak self] events in
                DispatchQueue.main.async {
                    self?.realTimeEvents = events
                }
            }
            .store(in: &cancellables)
        
        // 연결 상태 관찰
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
                // 회원가입 성공 시 자동 로그인
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
        // Socket 연결 해제
        socketManager.disconnect()
        
        // 네트워크 매니저 토큰 클리어
        networkManager.clearToken()
        
        // 상태 초기화
        isAuthenticated = false
        isOnlineMode = false
        connectionStatus = "오프라인"
        player = Player()
        realTimeEvents.removeAll()
        
        // 오프라인 데이터로 재설정
        generateOfflineData()
        
        // 타이머 정리
        locationUpdateTimer?.invalidate()
    }
    
    private func attemptOnlineMode() async {
        guard isAuthenticated else { return }
        
        do {
            // 소켓 연결 시작
            if let token = UserDefaults.standard.string(forKey: "auth_token") {
                socketManager.connect(with: token)
            }
            
            // 플레이어 데이터 로드
            await loadOnlineGameData()
            
        } catch {
            print("온라인 모드 진입 실패: \(error)")
            await setError("서버 연결에 실패했습니다. 오프라인 모드로 진행합니다.")
        }
    }
    
    // MARK: - Authentication Helpers
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
        
        // 통계 업데이트
        gameStats.level = playerInfo.level
        gameStats.experience = playerInfo.experience
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
        // Socket을 통한 실시간 데이터 요청
        if let location = currentLocation {
            socketManager.sendLocation(latitude: location.latitude, longitude: location.longitude)
            socketManager.requestMarketData()
            socketManager.requestNearbyPlayers(latitude: location.latitude, longitude: location.longitude)
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
        
        // 인벤토리 업데이트
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
        
        // 자산 업데이트
        updatePlayerAssets(data)
        
        // 통계 업데이트
        gameStats.level = data.level
        gameStats.experience = data.experience
    }
    
    private func updatePlayerAssets(_ data: PlayerDetail) {
        // 차량 업데이트
        player.vehicles = data.vehicles.map { vehicleData in
            Vehicle(
                name: vehicleData.name,
                type: Vehicle.VehicleType(rawValue: vehicleData.type) ?? .cart,
                price: 0, // 이미 구매한 것이므로 가격은 0
                inventoryBonus: vehicleData.inventoryBonus,
                speedBonus: vehicleData.speedBonus,
                owned: true
            )
        }
        
        // 펫 업데이트
        player.pets = data.pets.map { petData in
            Pet(
                name: petData.name,
                type: Pet.PetType(rawValue: petData.type) ?? .dog,
                price: 0,
                specialAbility: petData.specialAbility,
                owned: true
            )
        }
        
        // 부동산 업데이트 (CLLocationCoordinate2D 처리)
        player.ownedProperties = data.properties.map { propertyData in
            Property(
                name: propertyData.name,
                type: Property.PropertyType(rawValue: propertyData.type) ?? .house,
                district: SeoulDistrict(rawValue: propertyData.district) ?? .gangnam,
                coordinate: CLLocationCoordinate2D(
                    latitude: propertyData.location.lat,
                    longitude: propertyData.location.lng
                ),
                purchasePrice: 0,
                dailyIncome: propertyData.dailyIncome,
                owned: true
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
            inventory: inventory,
            trustLevel: data.trustLevel
        )
    }
}

// MARK: - Real-time Updates
extension GameManager {
    private func applyPriceUpdates(_ updates: [String: Int]) {
        guard !updates.isEmpty else { return }
        
        // 가격 보드 업데이트
        for (itemName, newPrice) in updates {
            if var boardEntry = priceBoard[itemName] {
                boardEntry.price = newPrice
                priceBoard[itemName] = boardEntry
            }
        }
        
        // 상인 인벤토리의 아이템 가격 업데이트
        for i in merchants.indices {
            for j in merchants[i].inventory.indices {
                if let newPrice = updates[merchants[i].inventory[j].name] {
                    merchants[i].inventory[j].currentPrice = newPrice
                }
            }
        }
        
        // 사용 가능한 아이템들의 가격도 업데이트
        for i in availableItems.indices {
            if let newPrice = updates[availableItems[i].name] {
                availableItems[i].currentPrice = newPrice
            }
        }
    }
    
    private func updateNearbyMerchants(_ nearbyMerchants: [Merchant]) {
        // 기존 상인 목록과 병합하여 중복 제거
        var updatedMerchants = merchants
        
        for nearbyMerchant in nearbyMerchants {
            if let index = updatedMerchants.firstIndex(where: { $0.id == nearbyMerchant.id }) {
                // 기존 상인 정보 업데이트
                updatedMerchants[index] = nearbyMerchant
            } else {
                // 새로운 상인 추가
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
        
        socketManager.sendLocation(latitude: location.latitude, longitude: location.longitude)
        
        // 주기적으로 주변 정보 요청
        socketManager.requestNearbyPlayers(latitude: location.latitude, longitude: location.longitude)
    }
    
    func updatePlayerLocation(_ location: CLLocationCoordinate2D) {
        currentLocation = location
        
        if isOnlineMode {
            socketManager.sendLocation(latitude: location.latitude, longitude: location.longitude)
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
    
    // MARK: - Online Trading
    private func buyItemOnline(_ item: TradeItem, from merchant: Merchant) async -> Bool {
        do {
            let response = try await networkManager.buyItem(
                merchantId: merchant.id,
                itemName: item.name
            )
            
            if response.success, let data = response.data {
                await updatePlayerAfterPurchase(data)
                await updateGameStatistics(profit: 0, trade: true)
                
                // Socket으로 거래 알림
                socketManager.sendTradeRequest(
                    merchantId: merchant.id,
                    itemName: item.name,
                    action: "buy"
                )
                
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
                await updateGameStatistics(profit: data.profit ?? 0, trade: true)
                
                // Socket으로 거래 알림
                socketManager.sendTradeRequest(
                    merchantId: merchant.id,
                    itemName: item.name,
                    action: "sell"
                )
                
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
        
        Task {
            await updateGameStatistics(profit: 0, trade: true)
        }
        
        return true
    }
    
    private func sellItemOffline(_ item: TradeItem, to merchant: Merchant, at location: CLLocationCoordinate2D) -> Bool {
        guard let index = player.inventory.firstIndex(where: { $0.id == item.id }) else {
            return false
        }
        
        let finalPrice = calculateSalePrice(item, merchantLocation: merchant.coordinate, playerLocation: location)
        let profit = finalPrice - item.currentPrice
        
        player.money += finalPrice
        player.inventory.remove(at: index)
        player.trustPoints += 2
        
        Task {
            await updateGameStatistics(profit: profit, trade: true)
        }
        
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
    
    private func updatePlayerAfterPurchase(_ data: TradeResult) async {
        await MainActor.run {
            self.player.money = data.newMoney
            self.player.trustPoints = data.newTrustPoints
            
            if let acquiredItem = data.acquiredItem {
                let newItem = TradeItem(
                    name: acquiredItem.name,
                    category: acquiredItem.category,
                    basePrice: acquiredItem.basePrice,
                    grade: ItemGrade(rawValue: acquiredItem.grade) ?? .common,
                    requiredLicense: LicenseLevel(rawValue: acquiredItem.requiredLicense) ?? .beginner,
                    currentPrice: acquiredItem.currentPrice
                )
                self.player.inventory.append(newItem)
            }
        }
    }
    
    private func updatePlayerAfterSale(_ data: TradeResult, itemId: String) async {
        await MainActor.run {
            self.player.money = data.newMoney
            self.player.trustPoints = data.newTrustPoints
            
            if let index = self.player.inventory.firstIndex(where: { $0.id.uuidString == itemId }) {
                self.player.inventory.remove(at: index)
            }
        }
    }
}

// MARK: - Shop Functions
extension GameManager {
    func purchaseVehicle(_ vehicle: Vehicle) async -> Bool {
        if isOnlineMode {
            return await purchaseVehicleOnline(vehicle)
        } else {
            return purchaseVehicleOffline(vehicle)
        }
    }
    
    func purchasePet(_ pet: Pet) async -> Bool {
        if isOnlineMode {
            return await purchasePetOnline(pet)
        } else {
            return purchasePetOffline(pet)
        }
    }
    
    func purchaseProperty(_ property: Property) async -> Bool {
        if isOnlineMode {
            return await purchasePropertyOnline(property)
        } else {
            return purchasePropertyOffline(property)
        }
    }
    
    func upgradeLicense() async -> Bool {
        if isOnlineMode {
            return await upgradeLicenseOnline()
        } else {
            return upgradeLicenseOffline()
        }
    }
    
    // MARK: - Online Shop Functions
    private func purchaseVehicleOnline(_ vehicle: Vehicle) async -> Bool {
        do {
            let response = try await networkManager.purchaseVehicle(vehicleId: vehicle.id)
            
            if response.success {
                await MainActor.run {
                    self.player.money = response.data?.newMoney ?? self.player.money
                    self.player.maxInventorySize += vehicle.inventoryBonus
                    self.player.vehicles.append(vehicle)
                }
                return true
            } else {
                await setError("차량 구매 실패")
                return false
            }
        } catch {
            await setError(error.localizedDescription)
            return false
        }
    }
    
    private func purchasePetOnline(_ pet: Pet) async -> Bool {
        do {
            let response = try await networkManager.purchasePet(petId: pet.id)
            
            if response.success {
                await MainActor.run {
                    self.player.money = response.data?.newMoney ?? self.player.money
                    self.player.pets.append(pet)
                }
                return true
            } else {
                await setError("펫 구매 실패")
                return false
            }
        } catch {
            await setError(error.localizedDescription)
            return false
        }
    }
    
    private func purchasePropertyOnline(_ property: Property) async -> Bool {
        do {
            let response = try await networkManager.purchaseProperty(propertyId: property.id)
            
            if response.success {
                await MainActor.run {
                    self.player.money = response.data?.newMoney ?? self.player.money
                    self.player.ownedProperties.append(property)
                }
                return true
            } else {
                await setError("부동산 구매 실패")
                return false
            }
        } catch {
            await setError(error.localizedDescription)
            return false
        }
    }
    
    private func upgradeLicenseOnline() async -> Bool {
        do {
            let response = try await networkManager.upgradeLicense()
            
            if response.success, let data = response.data {
                await MainActor.run {
                    self.player.currentLicense = LicenseLevel(rawValue: data.newLicense) ?? self.player.currentLicense
                    self.player.maxInventorySize = data.newMaxInventorySize
                    self.player.money = data.newMoney
                }
                return true
            } else {
                await setError("라이센스 업그레이드 실패")
                return false
            }
        } catch {
            await setError(error.localizedDescription)
            return false
        }
    }
    
    // MARK: - Offline Shop Functions
    private func purchaseVehicleOffline(_ vehicle: Vehicle) -> Bool {
        guard player.money >= vehicle.price else { return false }
        
        player.money -= vehicle.price
        player.maxInventorySize += vehicle.inventoryBonus
        player.vehicles.append(vehicle)
        
        return true
    }
    
    private func purchasePetOffline(_ pet: Pet) -> Bool {
        guard player.money >= pet.price else { return false }
        
        player.money -= pet.price
        player.pets.append(pet)
        
        return true
    }
    
    private func purchasePropertyOffline(_ property: Property) -> Bool {
        guard player.money >= property.purchasePrice else { return false }
        
        player.money -= property.purchasePrice
        player.ownedProperties.append(property)
        
        return true
    }
    
    private func upgradeLicenseOffline() -> Bool {
        return player.upgradeLicense()
    }
}

// MARK: - Offline Data Generation
extension GameManager {
    private func generateOfflineData() {
        generateTradeItems()
        generateMerchants()
        updatePriceBoard()
        startItemResetTimer()
    }
    
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
                    inventory: generateMerchantInventory(for: merchantType),
                    trustLevel: Int.random(in: 0...100)
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
        itemResetTimer?.invalidate()
        itemResetTimer = Timer.scheduledTimer(withTimeInterval: 3 * 60 * 60, repeats: true) { [weak self] _ in
            self?.resetItemPrices()
        }
    }
    
    private func resetItemPrices() {
        // 온라인 모드에서는 서버에서 가격을 관리하므로 스킵
        guard !isOnlineMode else { return }
        
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

// MARK: - Game Statistics
extension GameManager {
    private func updateGameStatistics(profit: Int, trade: Bool) async {
        await MainActor.run {
            if trade {
                self.gameStats.totalTrades += 1
            }
            
            if profit > 0 {
                self.gameStats.totalProfit += profit
                self.gameStats.bestProfit = max(self.gameStats.bestProfit, profit)
            }
            
            // 경험치 추가 (온라인 모드에서는 서버에서 관리)
            if !self.isOnlineMode && trade {
                self.gameStats.experience += 10
                self.checkLevelUp()
            }
        }
    }
    
    private func checkLevelUp() {
        let requiredExp = gameStats.level * 100
        if gameStats.experience >= requiredExp {
            gameStats.level += 1
            gameStats.experience -= requiredExp
            
            // 레벨업 보상
            player.money += gameStats.level * 1000
            player.trustPoints += 5
        }
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
    
    private func clearError() {
        Task { @MainActor in
            errorMessage = nil
        }
    }
}

// MARK: - Game Statistics Model
struct GameStatistics {
    var level: Int = 1
    var experience: Int = 0
    var totalTrades: Int = 0
    var totalProfit: Int = 0
    var bestProfit: Int = 0
    var playTime: TimeInterval = 0
    var distanceTraveled: Double = 0
    var merchantsDiscovered: Int = 0
}
