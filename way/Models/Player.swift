// 📁 Models/Player.swift
import Foundation

class Player: ObservableObject {
    @Published var name: String = ""
    @Published var money: Int = 50000
    @Published var trustPoints: Int = 0
    @Published var currentLicense: LicenseLevel = .beginner
    @Published var inventory: [TradeItem] = []
    @Published var maxInventorySize: Int = 5
    
    @Published var ownedProperties: [Property] = []
    @Published var vehicles: [Vehicle] = []
    @Published var pets: [Pet] = []
    
    func canUpgradeLicense() -> Bool {
        let nextLevel = LicenseLevel(rawValue: currentLicense.rawValue + 1)
        guard let next = nextLevel else { return false }
        
        return money >= next.requiredMoney && trustPoints >= next.requiredTrust
    }
    
    func upgradeLicense() -> Bool {
        guard canUpgradeLicense() else { return false }
        
        let nextLevel = LicenseLevel(rawValue: currentLicense.rawValue + 1)!
        money -= nextLevel.requiredMoney
        currentLicense = nextLevel
        maxInventorySize += 2
        
        return true
    }
}
