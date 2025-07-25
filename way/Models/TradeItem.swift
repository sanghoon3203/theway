// 📁 Models/TradeItem.swift
import Foundation

struct TradeItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let category: String
    let basePrice: Int
    let grade: ItemGrade
    let requiredLicense: LicenseLevel
    var currentPrice: Int
    var demandMultiplier: Double = 1.0
    let resetInterval: TimeInterval = 3 * 60 * 60 // 3시간
    var lastReset: Date = Date()
    
    mutating func updatePrice(for region: SeoulDistrict) {
        let regionMultiplier = region.priceMultiplier(for: category)
        currentPrice = Int(Double(basePrice) * demandMultiplier * regionMultiplier)
    }
}
