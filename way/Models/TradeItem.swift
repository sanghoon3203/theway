// 📁 Models/TradeItem.swift - 확장된 아이템 시스템
import Foundation

struct TradeItem: Identifiable, Codable {
    let id: String  // 개별 아이템 인스턴스 ID
    let itemId: String  // 아이템 마스터 ID (item_master 테이블 참조)
    let name: String
    let category: ItemCategory
    let subcategory: String?
    let rarity: ItemRarity
    
    // 가격 정보
    let basePrice: Int
    var currentPrice: Int
    var marketValue: Int
    
    // 아이템 속성
    var quantity: Int = 1
    var currentDurability: Int?
    var maxDurability: Int?
    var enhancementLevel: Int = 0
    var weight: Double = 1.0
    
    // 요구사항
    let requiredLevel: Int
    let requiredLicense: LicenseLevel
    let requiredStats: RequiredStats?
    
    // 설명 및 배경
    let description: String?
    let loreText: String?
    
    // 특수 속성
    var magicalProperties: [MagicalProperty] = []
    var enchantments: [Enchantment] = []
    var socketGems: [SocketGem] = []
    
    // 상태 정보
    var isEquipped: Bool = false
    var equipmentSlot: EquipmentSlot?
    var isLocked: Bool = false
    var isFavorite: Bool = false
    var customName: String?
    
    // 거래 정보
    let purchasePrice: Int?
    let acquiredAt: Date
    
    // 플래그
    let isStackable: Bool
    let maxStack: Int
    let isTradeable: Bool
    let isDropable: Bool
    let isConsumable: Bool
    
    // 표시용 이름 (커스텀 이름이 있으면 사용)
    var displayName: String {
        return customName ?? name
    }
    
    // 강화된 이름 표시 (+5 강철검 같은 형태)
    var enhancedDisplayName: String {
        var result = displayName
        if enhancementLevel > 0 {
            result = "+\(enhancementLevel) \(result)"
        }
        return result
    }
    
    // 현재 내구도 비율
    var durabilityRatio: Double? {
        guard let current = currentDurability, let max = maxDurability else { return nil }
        return Double(current) / Double(max)
    }
    
    // 아이템 상태 텍스트
    var conditionText: String {
        guard let ratio = durabilityRatio else { return "완벽함" }
        
        switch ratio {
        case 0.9...1.0: return "완벽함"
        case 0.7..<0.9: return "양호함"
        case 0.5..<0.7: return "보통"
        case 0.3..<0.5: return "낡음"
        case 0.1..<0.3: return "매우 낡음"
        default: return "파손 직전"
        }
    }
    
    // 강화 가능 여부
    var canEnhance: Bool {
        return enhancementLevel < 15 && !isConsumable
    }
    
    // 소켓 가능 여부
    var canSocket: Bool {
        return !isConsumable && rarity.rawValue >= ItemRarity.rare.rawValue
    }
    
    // 총 가치 계산 (강화, 인챈트 등 포함)
    var totalValue: Int {
        var value = currentPrice
        
        // 강화 보너스
        if enhancementLevel > 0 {
            value += Int(Double(basePrice) * 0.2 * Double(enhancementLevel))
        }
        
        // 인챈트 보너스
        for enchantment in enchantments {
            value += enchantment.valueBonus
        }
        
        // 소켓 젬 보너스
        for gem in socketGems {
            value += gem.value
        }
        
        return value
    }
}

// MARK: - 아이템 카테고리
enum ItemCategory: String, CaseIterable, Codable {
    case weapon = "weapon"          // 무기
    case armor = "armor"            // 방어구
    case accessory = "accessory"    // 악세서리
    case potion = "potion"          // 물약
    case material = "material"      // 재료
    case artifact = "artifact"      // 고대 유물
    case modern = "modern"          // 현대 아이템
    case food = "food"              // 음식
    case consumable = "consumable"  // 소모품
    
    var displayName: String {
        switch self {
        case .weapon: return "무기"
        case .armor: return "방어구"
        case .accessory: return "악세서리"
        case .potion: return "물약"
        case .material: return "재료"
        case .artifact: return "고대 유물"
        case .modern: return "현대 아이템"
        case .food: return "음식"
        case .consumable: return "소모품"
        }
    }
    
    var iconName: String {
        switch self {
        case .weapon: return "sword.fill"
        case .armor: return "shield.fill"
        case .accessory: return "ring.fill"
        case .potion: return "testtube.2"
        case .material: return "cube.fill"
        case .artifact: return "scroll.fill"
        case .modern: return "laptopcomputer"
        case .food: return "fork.knife"
        case .consumable: return "pill.fill"
        }
    }
    
    var color: String {
        switch self {
        case .weapon: return "red"
        case .armor: return "blue"
        case .accessory: return "purple"
        case .potion: return "green"
        case .material: return "brown"
        case .artifact: return "gold"
        case .modern: return "gray"
        case .food: return "orange"
        case .consumable: return "cyan"
        }
    }
}

// MARK: - 아이템 희귀도
enum ItemRarity: Int, CaseIterable, Codable {
    case common = 1         // 커먼 (회색)
    case uncommon = 2       // 언커먼 (녹색)
    case rare = 3           // 레어 (파란색)
    case epic = 4           // 에픽 (보라색)
    case legendary = 5      // 레전더리 (주황색)
    case mythical = 6       // 신화 (빨간색)
    
    var displayName: String {
        switch self {
        case .common: return "커먼"
        case .uncommon: return "언커먼"
        case .rare: return "레어"
        case .epic: return "에픽"
        case .legendary: return "레전더리"
        case .mythical: return "신화"
        }
    }
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "green"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        case .mythical: return "red"
        }
    }
    
    var priceMultiplier: Double {
        switch self {
        case .common: return 1.0
        case .uncommon: return 1.5
        case .rare: return 2.5
        case .epic: return 5.0
        case .legendary: return 10.0
        case .mythical: return 20.0
        }
    }
    
    var maxEnhancementLevel: Int {
        switch self {
        case .common: return 5
        case .uncommon: return 8
        case .rare: return 10
        case .epic: return 12
        case .legendary: return 15
        case .mythical: return 20
        }
    }
}

// MARK: - 요구 스탯
struct RequiredStats: Codable {
    let strength: Int?
    let intelligence: Int?
    let charisma: Int?
    let luck: Int?
    
    func meetsRequirements(player: Player) -> Bool {
        if let req = strength, player.strength < req { return false }
        if let req = intelligence, player.intelligence < req { return false }
        if let req = charisma, player.charisma < req { return false }
        if let req = luck, player.luck < req { return false }
        return true
    }
    
    var description: String {
        var parts: [String] = []
        if let str = strength { parts.append("힘 \(str)") }
        if let int = intelligence { parts.append("지능 \(int)") }
        if let cha = charisma { parts.append("매력 \(cha)") }
        if let lck = luck { parts.append("운 \(lck)") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - 장비 슬롯
enum EquipmentSlot: String, CaseIterable, Codable {
    case weapon = "weapon"
    case armor = "armor"
    case accessory1 = "accessory1"
    case accessory2 = "accessory2"
    
    var displayName: String {
        switch self {
        case .weapon: return "무기"
        case .armor: return "방어구"
        case .accessory1: return "악세서리 1"
        case .accessory2: return "악세서리 2"
        }
    }
}

// MARK: - 마법 속성
struct MagicalProperty: Identifiable, Codable {
    let id: String
    let name: String
    let type: MagicType
    let effectValue: Double
    let description: String
    
    enum MagicType: String, CaseIterable, Codable {
        case elemental = "elemental"        // 원소 속성
        case statBoost = "stat_boost"       // 스탯 증가
        case specialAbility = "special_ability"  // 특수 능력
        case curse = "curse"                // 저주
        
        var displayName: String {
            switch self {
            case .elemental: return "원소"
            case .statBoost: return "스탯 강화"
            case .specialAbility: return "특수 능력"
            case .curse: return "저주"
            }
        }
    }
}

// MARK: - 인챈트
struct Enchantment: Identifiable, Codable {
    let id: String
    let name: String
    let level: Int
    let effectDescription: String
    let valueBonus: Int
    
    var displayText: String {
        return "\(name) Lv.\(level)"
    }
}

// MARK: - 소켓 젬
struct SocketGem: Identifiable, Codable {
    let id: String
    let name: String
    let type: GemType
    let value: Int
    let effectDescription: String
    
    enum GemType: String, CaseIterable, Codable {
        case ruby = "ruby"          // 루비 (힘)
        case sapphire = "sapphire"  // 사파이어 (지능)
        case emerald = "emerald"    // 에메랄드 (매력)
        case diamond = "diamond"    // 다이아몬드 (운)
        
        var displayName: String {
            switch self {
            case .ruby: return "루비"
            case .sapphire: return "사파이어"
            case .emerald: return "에메랄드"
            case .diamond: return "다이아몬드"
            }
        }
        
        var color: String {
            switch self {
            case .ruby: return "red"
            case .sapphire: return "blue"
            case .emerald: return "green"
            case .diamond: return "white"
            }
        }
    }
}

// MARK: - 아이템 생성 헬퍼
extension TradeItem {
    // 서버 데이터로부터 아이템 생성
    static func fromServerData(_ data: [String: Any]) -> TradeItem? {
        guard let id = data["id"] as? String,
              let itemId = data["item_id"] as? String,
              let name = data["name"] as? String,
              let categoryString = data["category"] as? String,
              let category = ItemCategory(rawValue: categoryString),
              let rarityInt = data["rarity"] as? Int,
              let rarity = ItemRarity(rawValue: rarityInt),
              let basePrice = data["base_price"] as? Int,
              let currentPrice = data["current_price"] as? Int,
              let requiredLevel = data["required_level"] as? Int,
              let requiredLicenseInt = data["required_license"] as? Int,
              let requiredLicense = LicenseLevel(rawValue: requiredLicenseInt) else {
            return nil
        }
        
        return TradeItem(
            id: id,
            itemId: itemId,
            name: name,
            category: category,
            subcategory: data["subcategory"] as? String,
            rarity: rarity,
            basePrice: basePrice,
            currentPrice: currentPrice,
            marketValue: data["market_value"] as? Int ?? currentPrice,
            quantity: data["quantity"] as? Int ?? 1,
            currentDurability: data["current_durability"] as? Int,
            maxDurability: data["durability"] as? Int,
            enhancementLevel: data["enhancement_level"] as? Int ?? 0,
            weight: data["weight"] as? Double ?? 1.0,
            requiredLevel: requiredLevel,
            requiredLicense: requiredLicense,
            requiredStats: parseRequiredStats(data["required_stats"]),
            description: data["description"] as? String,
            loreText: data["lore_text"] as? String,
            isEquipped: data["is_equipped"] as? Bool ?? false,
            equipmentSlot: parseEquipmentSlot(data["equipment_slot"]),
            isLocked: data["is_locked"] as? Bool ?? false,
            isFavorite: data["is_favorite"] as? Bool ?? false,
            customName: data["custom_name"] as? String,
            purchasePrice: data["purchase_price"] as? Int,
            acquiredAt: parseDate(data["acquired_at"]) ?? Date(),
            isStackable: data["is_stackable"] as? Bool ?? false,
            maxStack: data["max_stack"] as? Int ?? 1,
            isTradeable: data["is_tradeable"] as? Bool ?? true,
            isDropable: data["is_dropable"] as? Bool ?? true,
            isConsumable: data["is_consumable"] as? Bool ?? false
        )
    }
    
    private static func parseRequiredStats(_ data: Any?) -> RequiredStats? {
        // JSON 파싱 로직 구현
        return nil
    }
    
    private static func parseEquipmentSlot(_ data: Any?) -> EquipmentSlot? {
        guard let slotString = data as? String else { return nil }
        return EquipmentSlot(rawValue: slotString)
    }
    
    private static func parseDate(_ data: Any?) -> Date? {
        guard let dateString = data as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}
