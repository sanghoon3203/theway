// 📁 Core/GameManager.swift
import Foundation
import SwiftUI
import CoreLocation

class GameManager: ObservableObject {
    @Published var player = Player()
    @Published var merchants: [Merchant] = []
    @Published var availableItems: [TradeItem] = []
    @Published var priceBoard: [String: (district: SeoulDistrict, price: Int)] = [:]
    
    private var itemResetTimer: Timer?
    
    init() {
        setupInitialData()
        startItemResetTimer()
    }
    
    // MARK: - 초기 데이터 설정
    private func setupInitialData() {
        generateTradeItems()
        generateMerchants()
        updatePriceBoard()
    }
    
    private func generateTradeItems() {
        let categories = ["IT부품", "명품", "예술품", "화장품", "서적", "생활용품"]
        
        for category in categories {
            for grade in ItemGrade.allCases {
                let item = TradeItem(
                    name: "\(category) (\(grade.rawValue))",
                    category: category,
                    basePrice: basePrice(for: grade),
                    grade: grade,
                    requiredLicense: requiredLicense(for: grade),
                    currentPrice: basePrice(for: grade)
                )
                availableItems.append(item)
            }
        }
    }
    
    private func generateMerchants() {
        for district in SeoulDistrict.allCases {
            for merchantType in Merchant.MerchantType.allCases {
                let merchant = Merchant(
                    name: "\(district.rawValue) \(merchantType.rawValue)",
                    type: merchantType,
                    district: district,
                    coordinate: randomCoordinate(for: district),
                    requiredLicense: requiredLicense(for: merchantType),
                    inventory: generateMerchantInventory(for: merchantType)
                )
                merchants.append(merchant)
            }
        }
    }
    
    // MARK: - 헬퍼 메서드
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
        // 임시로 서울 중심부 기준 (나중에 실제 구별 좌표로 교체)
        let baseLatitude = 37.5665
        let baseLongitude = 126.9780
        
        return CLLocationCoordinate2D(
            latitude: baseLatitude + Double.random(in: -0.05...0.05),
            longitude: baseLongitude + Double.random(in: -0.05...0.05)
        )
    }
    
    private func generateMerchantInventory(for type: Merchant.MerchantType) -> [TradeItem] {
        return availableItems.filter { item in
            item.grade.rawValue <= type.maxItemGrade.rawValue
        }.shuffled().prefix(Int.random(in: 3...8)).map { $0 }
    }
    
    // MARK: - 가격 시스템
    private func updatePriceBoard() {
        var board: [String: (district: SeoulDistrict, price: Int)] = [:]
        
        for item in availableItems {
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
            
            board[item.name] = (district: bestDistrict, price: bestPrice)
        }
        
        priceBoard = board
    }
    
    private func startItemResetTimer() {
        itemResetTimer = Timer.scheduledTimer(withTimeInterval: 3 * 60 * 60, repeats: true) { _ in
            self.resetItemPrices()
        }
    }
    
    private func resetItemPrices() {
        for i in availableItems.indices {
            availableItems[i].demandMultiplier = Double.random(in: 0.5...2.0)
            availableItems[i].lastReset = Date()
        }
        
        for i in merchants.indices {
            merchants[i].inventory = generateMerchantInventory(for: merchants[i].type)
        }
        
        updatePriceBoard()
    }
    
    // MARK: - 거래 기능
    func buyItem(_ item: TradeItem, from merchant: Merchant) -> Bool {
        guard player.money >= item.currentPrice,
              player.inventory.count < player.maxInventorySize,
              player.currentLicense.rawValue >= item.requiredLicense.rawValue else {
            return false
        }
        
        player.money -= item.currentPrice
        player.inventory.append(item)
        player.trustPoints += 1
        
        return true
    }
    
    func sellItem(_ item: TradeItem, to merchant: Merchant, at location: CLLocationCoordinate2D) -> Bool {
        guard let index = player.inventory.firstIndex(where: { $0.id == item.id }) else {
            return false
        }
        
        let distance = calculateDistance(from: location, to: merchant.coordinate)
        let distanceBonus = min(distance / 1000 * 0.1, 0.5) // 1km당 10%, 최대 50%
        let finalPrice = Int(Double(item.currentPrice) * (1.0 + distanceBonus))
        
        player.money += finalPrice
        player.inventory.remove(at: index)
        player.trustPoints += 2
        
        return true
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let location2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return location1.distance(from: location2)
    }
}
