// 📁 Models/Player.swift - 확장된 플레이어 모델
import Foundation
import CoreLocation

struct Player: Codable {
    var id: String = UUID().uuidString
    var name: String = "플레이어"
    var money: Int = 50000
    var trustPoints: Int = 0
    var currentLicense: LicenseLevel = .beginner
    var maxInventorySize: Int = 5
    
    // 새로운 캐릭터 시스템
    var level: Int = 1
    var experience: Int = 0
    var statPoints: Int = 0
    var skillPoints: Int = 0
    
    // 캐릭터 스탯
    var strength: Int = 10      // 힘 (운반 용량 증가)
    var intelligence: Int = 10  // 지능 (시세 파악 능력)
    var charisma: Int = 10      // 매력 (거래 가격 우대)
    var luck: Int = 10          // 운 (희귀 아이템 발견율)
    
    // 스킬 레벨
    var tradingSkill: Int = 1      // 거래 스킬
    var negotiationSkill: Int = 1   // 협상 스킬
    var appraisalSkill: Int = 1     // 감정 스킬
    
    // 기존 시스템
    var inventory: [TradeItem] = []
    var vehicles: [Vehicle] = []
    var pets: [Pet] = []
    var ownedProperties: [Property] = []
    
    // 캐릭터 외형
    var appearance: CharacterAppearance = CharacterAppearance()
    
    // 업적 및 관계
    var completedAchievements: [String] = []
    var merchantRelations: [String: MerchantRelation] = [:]
    
    // 계산된 속성들
    var actualInventorySize: Int {
        return maxInventorySize + (strength / 5) // 힘 5마다 인벤토리 +1
    }
    
    var negotiationBonus: Double {
        return Double(charisma) * 0.02 + Double(negotiationSkill) * 0.05 // 매력과 협상 스킬 보너스
    }
    
    var luckBonus: Double {
        return Double(luck) * 0.01 // 운 1당 1% 보너스
    }
    
    var appraisalAccuracy: Double {
        return min(0.5 + Double(intelligence) * 0.02 + Double(appraisalSkill) * 0.1, 0.95) // 최대 95%
    }
    
    // 레벨업에 필요한 경험치
    var requiredExpForNextLevel: Int {
        return calculateRequiredExp(for: level + 1)
    }
    
    // 현재 레벨 진행률 (0.0 - 1.0)
    var levelProgress: Double {
        let currentLevelExp = calculateRequiredExp(for: level)
        let nextLevelExp = calculateRequiredExp(for: level + 1)
        let progressExp = experience - currentLevelExp
        let totalExpNeeded = nextLevelExp - currentLevelExp
        return Double(progressExp) / Double(totalExpNeeded)
    }
    
    // 인벤토리에 공간이 있는지 확인
    var hasInventorySpace: Bool {
        return inventory.count < actualInventorySize
    }
    
    private func calculateRequiredExp(for level: Int) -> Int {
        switch level {
        case 1: return 0
        case 2: return 100
        case 3: return 250
        case 4: return 450
        case 5: return 700
        case 6...10: return 700 + (level - 5) * 400
        case 11...20: return 2700 + (level - 10) * 500
        case 21...30: return 7700 + (level - 20) * 750
        case 31...50: return 15200 + (level - 30) * 1000
        default: return 35200 + (level - 50) * 1500
        }
    }
    
    // 레벨업 체크 및 처리
    mutating func checkLevelUp() -> Bool {
        if experience >= requiredExpForNextLevel {
            levelUp()
            return true
        }
        return false
    }
    
    private mutating func levelUp() {
        level += 1
        
        // 레벨별 보상
        let rewards = getLevelRewards(for: level)
        statPoints += rewards.statPoints
        skillPoints += rewards.skillPoints
        
        print("🎉 레벨업! 레벨 \(level)이 되었습니다!")
        print("스탯 포인트 +\(rewards.statPoints), 스킬 포인트 +\(rewards.skillPoints)")
    }
    
    private func getLevelRewards(for level: Int) -> (statPoints: Int, skillPoints: Int) {
        switch level {
        case 2...4: return (2, 1)
        case 5, 10, 15, 20: return (3, 2)
        case 25, 30: return (4, 3)
        case 35, 40: return (5, 3)
        case 45: return (5, 4)
        case 50: return (6, 5)
        default: return (2, 1)
        }
    }
    
    // 스탯 증가 메서드
    mutating func increaseStat(_ stat: StatType) -> Bool {
        guard statPoints > 0 else { return false }
        
        switch stat {
        case .strength:
            strength += 1
        case .intelligence:
            intelligence += 1
        case .charisma:
            charisma += 1
        case .luck:
            luck += 1
        }
        
        statPoints -= 1
        return true
    }
    
    // 스킬 증가 메서드
    mutating func increaseSkill(_ skill: SkillType) -> Bool {
        guard skillPoints > 0 else { return false }
        
        switch skill {
        case .trading:
            tradingSkill += 1
        case .negotiation:
            negotiationSkill += 1
        case .appraisal:
            appraisalSkill += 1
        }
        
        skillPoints -= 1
        return true
    }
    
    // 경험치 획득
    mutating func gainExperience(_ amount: Int) {
        experience += amount
        _ = checkLevelUp()
    }
    
    // MARK: - 추가된 메서드들
    
    // 라이센스 업그레이드 가능 여부
    func canUpgradeLicense() -> Bool {
        let currentLevel = currentLicense.rawValue
        guard currentLevel < 5 else { return false }
        
        let nextLevel = LicenseLevel(rawValue: currentLevel + 1) ?? .master
        let requirements = nextLevel.requirements
        
        return money >= requirements.requiredMoney &&
               trustPoints >= requirements.requiredTrust
    }
    
    // 라이센스 업그레이드 실행
    mutating func upgradeLicense() -> Bool {
        guard canUpgradeLicense() else { return false }
        
        let nextLevel = LicenseLevel(rawValue: currentLicense.rawValue + 1) ?? .master
        let requirements = nextLevel.requirements
        
        money -= requirements.requiredMoney
        trustPoints -= requirements.requiredTrust
        currentLicense = nextLevel
        
        return true
    }
    
    // 아이템 거래 가능 여부 확인
    func canTradeItem(_ item: TradeItem) -> Bool {
        return currentLicense.rawValue >= item.requiredLicense.rawValue &&
               level >= item.requiredLevel &&
               (item.requiredStats?.meetsRequirements(player: self) ?? true)
    }
    
    // 특정 금액을 구매할 수 있는지 확인
    func canAfford(_ amount: Int) -> Bool {
        return money >= amount
    }
    
    // 아이템 구매 처리
    mutating func buyItem(_ item: TradeItem, price: Int) -> Bool {
        guard canAfford(price) && hasInventorySpace else { return false }
        
        money -= price
        inventory.append(item)
        
        // 경험치 획득
        let expGained = max(1, price / 1000)
        gainExperience(expGained)
        
        return true
    }
    
    // 아이템 판매 처리
    mutating func sellItem(_ item: TradeItem, price: Int) -> Bool {
        guard let index = inventory.firstIndex(where: { $0.id == item.id }) else { return false }
        
        inventory.remove(at: index)
        money += price
        trustPoints += 1
        
        // 경험치 획득
        let expGained = max(1, price / 500)
        gainExperience(expGained)
        
        return true
    }
    
    // 상인과의 관계 업데이트
    mutating func updateMerchantRelation(merchantId: String, tradeAmount: Int, wasSuccessful: Bool) {
        if merchantRelations[merchantId] == nil {
            merchantRelations[merchantId] = MerchantRelation(merchantId: merchantId)
        }
        
        merchantRelations[merchantId]?.recordTrade(amount: tradeAmount, wasSuccessful: wasSuccessful)
    }
}

// MARK: - 캐릭터 외형 시스템
struct CharacterAppearance: Codable {
    var hairStyle: Int = 1      // 1-10
    var hairColor: Int = 1      // 1-8
    var faceType: Int = 1       // 1-6
    var eyeType: Int = 1        // 1-8
    var skinTone: Int = 1       // 1-5
    var outfitId: Int = 1       // 현재 착용 의상
    var accessoryId: Int? = nil  // 악세서리 (옵션)
    
    // 보유 의상/악세서리
    var ownedOutfits: [Int] = [1]  // 기본 의상은 1번
    var ownedAccessories: [Int] = []
}

// MARK: - 상인과의 관계 시스템
struct MerchantRelation: Codable {
    let merchantId: String
    var friendshipPoints: Int = 0
    var reputation: Int = 0
    var totalTrades: Int = 0
    var totalSpent: Int = 0
    var relationshipStatus: RelationshipStatus = .stranger
    var lastInteraction: Date? = nil
    var notes: String = ""
    
    enum RelationshipStatus: String, CaseIterable, Codable {
        case stranger = "stranger"      // 낯선 사람
        case acquaintance = "acquaintance"  // 아는 사람
        case friend = "friend"          // 친구
        case trusted = "trusted"        // 신뢰하는 사이
        case partner = "partner"        // 파트너
        
        var displayName: String {
            switch self {
            case .stranger: return "낯선 사람"
            case .acquaintance: return "아는 사람"
            case .friend: return "친구"
            case .trusted: return "신뢰하는 사이"
            case .partner: return "비즈니스 파트너"
            }
        }
        
        var color: String {
            switch self {
            case .stranger: return "gray"
            case .acquaintance: return "blue"
            case .friend: return "green"
            case .trusted: return "purple"
            case .partner: return "gold"
            }
        }
    }
    
    // 관계 레벨 계산
    var friendshipLevel: Int {
        return min(friendshipPoints / 100, 10) // 100포인트당 1레벨, 최대 10레벨
    }
    
    // 관계 상태 업데이트
    mutating func updateRelationshipStatus() {
        switch friendshipPoints {
        case 0...99:
            relationshipStatus = .stranger
        case 100...299:
            relationshipStatus = .acquaintance
        case 300...699:
            relationshipStatus = .friend
        case 700...1499:
            relationshipStatus = .trusted
        case 1500...:
            relationshipStatus = .partner
        default:
            relationshipStatus = .stranger
        }
    }
    
    // 거래 후 관계 업데이트
    mutating func recordTrade(amount: Int, wasSuccessful: Bool) {
        totalTrades += 1
        totalSpent += amount
        lastInteraction = Date()
        
        if wasSuccessful {
            friendshipPoints += max(1, amount / 1000) // 거래액에 비례한 우정 포인트
            reputation += 1
        }
        
        updateRelationshipStatus()
    }
}

// MARK: - 열거형들
enum StatType: String, CaseIterable {
    case strength = "strength"
    case intelligence = "intelligence"
    case charisma = "charisma"
    case luck = "luck"
    
    var displayName: String {
        switch self {
        case .strength: return "힘"
        case .intelligence: return "지능"
        case .charisma: return "매력"
        case .luck: return "운"
        }
    }
    
    var description: String {
        switch self {
        case .strength: return "운반 용량과 체력을 증가시킵니다"
        case .intelligence: return "시세 파악과 학습 능력을 향상시킵니다"
        case .charisma: return "거래 성공률과 가격 우대를 받습니다"
        case .luck: return "희귀 아이템 발견과 무작위 이벤트에 영향을 줍니다"
        }
    }
    
    var iconName: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .intelligence: return "brain.head.profile"
        case .charisma: return "heart.fill"
        case .luck: return "star.fill"
        }
    }
}

enum SkillType: String, CaseIterable {
    case trading = "trading"
    case negotiation = "negotiation"
    case appraisal = "appraisal"
    
    var displayName: String {
        switch self {
        case .trading: return "거래"
        case .negotiation: return "협상"
        case .appraisal: return "감정"
        }
    }
    
    var description: String {
        switch self {
        case .trading: return "거래에서 더 많은 경험치와 수익을 얻습니다"
        case .negotiation: return "가격 협상 성공률과 할인폭을 증가시킵니다"
        case .appraisal: return "아이템의 진짜 가치를 더 정확히 파악합니다"
        }
    }
    
    var iconName: String {
        switch self {
        case .trading: return "arrow.left.arrow.right"
        case .negotiation: return "bubble.left.and.bubble.right"
        case .appraisal: return "magnifyingglass"
        }
    }
}

// MARK: - LicenseLevel Extension
extension LicenseLevel {
    var requirements: (requiredMoney: Int, requiredTrust: Int) {
        switch self {
        case .beginner: return (0, 0)
        case .intermediate: return (100000, 50)
        case .advanced: return (500000, 200)
        case .expert: return (2000000, 500)
        case .master: return (10000000, 1000)
        }
    }
}
