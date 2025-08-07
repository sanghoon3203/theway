// 📁 Models/TradeItem.swift - 확장된 버전
import Foundation
import SwiftUI
// MARK: - 확장된 TradeItem
struct TradeItem: Identifiable, Codable, Equatable {
    let id = String
    // 기본 아이템 정보
    let itemId: String  // 서버의 item_master ID
    let name: String
    let category: String
    let subcategory: String?
    
    // 등급 및 요구사항
    let grade: ItemGrade
    let rarity: ItemRarity
    let requiredLicense: LicenseLevel
    let requiredLevel: Int
    let requiredStats: RequiredStats?
    
    // 가격 정보
    let basePrice: Int
    var currentPrice: Int
    var marketValue: Int?
    let purchasePrice: Int?  // 구매했을 때의 가격
    
    // 아이템 속성
    let weight: Double
    let durability: Int?
    var currentDurability: Int?
    let maxStack: Int
    let isStackable: Bool
    let isConsumable: Bool
    let isTradeable: Bool
    let isDropable: Bool
    
    // 강화 시스템
    var enhancementLevel: Int = 0
    var enhancementStats: EnhancementStats?
    var socketGems: [SocketGem] = []
    var enchantments: [Enchantment] = []
    var customName: String?
    
    // 마법 속성
    let magicalProperties: [MagicalProperty]
    let specialEffects: [SpecialEffect]
    
    // 외형 정보
    let iconId: Int
    let spriteId: Int?
    let colorScheme: String?
    
    // 설명 텍스트
    let description: String
    let loreText: String?
    
    // 인벤토리 관련
    var quantity: Int = 1
    var isEquipped: Bool = false
    var equipmentSlot: EquipmentSlot?
    var isLocked: Bool = false
    var isFavorite: Bool = false
    
    // 시간 정보
    let acquiredAt: Date
    var lastUsed: Date?
    
    // 시장 정보
    var demandMultiplier: Double = 1.0
    let resetInterval: TimeInterval = 3 * 60 * 60 // 3시간
    var lastReset: Date = Date()
    
    // MARK: - 초기화
    init(
        itemId: String,
        name: String,
        category: String,
        subcategory: String? = nil,
        grade: ItemGrade,
        rarity: ItemRarity = .common,
        requiredLicense: LicenseLevel,
        requiredLevel: Int = 1,
        requiredStats: RequiredStats? = nil,
        basePrice: Int,
        purchasePrice: Int? = nil,
        currentPrice: Int? = nil,
        weight: Double = 1.0,
        durability: Int? = nil,
        maxStack: Int = 1,
        isStackable: Bool = false,
        isConsumable: Bool = false,
        isTradeable: Bool = true,
        isDropable: Bool = true,
        magicalProperties: [MagicalProperty] = [],
        specialEffects: [SpecialEffect] = [],
        iconId: Int = 1,
        description: String = "",
        loreText: String? = nil,
        acquiredAt: Date = Date()
    ) {
        self.id = UUID().uuidString
        self.itemId = itemId
        self.name = name
        self.category = category
        self.subcategory = subcategory
        self.grade = grade
        self.rarity = rarity
        self.requiredLicense = requiredLicense
        self.requiredLevel = requiredLevel
        self.requiredStats = requiredStats
        self.basePrice = basePrice
        self.purchasePrice = purchasePrice  
        self.currentPrice = currentPrice ?? basePrice
        self.weight = weight
        self.durability = durability
        self.currentDurability = durability
        self.maxStack = maxStack
        self.isStackable = isStackable
        self.isConsumable = isConsumable
        self.isTradeable = isTradeable
        self.isDropable = isDropable
        self.magicalProperties = magicalProperties
        self.specialEffects = specialEffects
        self.iconId = iconId
        self.spriteId = nil
        self.colorScheme = nil
        self.description = description
        self.loreText = loreText
        self.acquiredAt = acquiredAt
    }
    
    // MARK: - 서버 응답용 초기화
    init(from serverItem: ServerItemResponse) {
        self.itemId = serverItem.id
        self.name = serverItem.name
        self.category = serverItem.category
        self.subcategory = serverItem.subcategory
        self.grade = ItemGrade(rawValue: serverItem.grade) ?? .common
        self.rarity = ItemRarity(rawValue: serverItem.rarity) ?? .common
        self.requiredLicense = LicenseLevel(rawValue: serverItem.requiredLicense) ?? .beginner
        self.requiredLevel = serverItem.requiredLevel
        self.requiredStats = serverItem.requiredStats
        self.basePrice = serverItem.basePrice
        self.currentPrice = serverItem.currentPrice ?? serverItem.basePrice
        self.marketValue = serverItem.marketValue
        self.purchasePrice = serverItem.purchasePrice
        self.weight = serverItem.weight
        self.durability = serverItem.durability
        self.currentDurability = serverItem.currentDurability ?? serverItem.durability
        self.maxStack = serverItem.maxStack
        self.isStackable = serverItem.isStackable
        self.isConsumable = serverItem.isConsumable
        self.isTradeable = serverItem.isTradeable
        self.isDropable = serverItem.isDropable
        self.enhancementLevel = serverItem.enhancementLevel
        self.enhancementStats = serverItem.enhancementStats
        self.socketGems = serverItem.socketGems ?? []
        self.enchantments = serverItem.enchantments ?? []
        self.customName = serverItem.customName
        self.magicalProperties = serverItem.magicalProperties ?? []
        self.specialEffects = serverItem.specialEffects ?? []
        self.iconId = serverItem.iconId
        self.spriteId = serverItem.spriteId
        self.colorScheme = serverItem.colorScheme
        self.description = serverItem.description
        self.loreText = serverItem.loreText
        self.quantity = serverItem.quantity
        self.isEquipped = serverItem.isEquipped
        self.equipmentSlot = serverItem.equipmentSlot
        self.isLocked = serverItem.isLocked
        self.isFavorite = serverItem.isFavorite
        self.acquiredAt = Date(timeIntervalSince1970: serverItem.acquiredAt)
        self.lastUsed = serverItem.lastUsed != nil ? Date(timeIntervalSince1970: serverItem.lastUsed!) : nil
    }
    
    // MARK: - 메서드들
    mutating func updatePrice(for region: SeoulDistrict) {
        let regionMultiplier = region.priceMultiplier(for: category)
        currentPrice = Int(Double(basePrice) * demandMultiplier * regionMultiplier)
    }
    
    func canUse(by player: Player) -> Bool {
        // 레벨 체크
        guard player.level >= requiredLevel else { return false }
        
        // 라이센스 체크
        guard player.currentLicense.rawValue >= requiredLicense.rawValue else { return false }
        
        // 스탯 체크
        if let reqStats = requiredStats {
            if player.strength < reqStats.strength ||
               player.intelligence < reqStats.intelligence ||
               player.charisma < reqStats.charisma ||
               player.luck < reqStats.luck {
                return false
            }
        }
        
        return true
    }
    
    func getTotalStats() -> ItemStats {
        var stats = ItemStats()
        
        // 마법 속성에서 스탯 추가
        for property in magicalProperties {
            stats = stats.adding(property.stats)
        }
        
        // 강화 스탯 추가
        if let enhanceStats = enhancementStats {
            stats = stats.adding(enhanceStats.bonusStats)
        }
        
        // 소켓 젬에서 스탯 추가
        for gem in socketGems {
            stats = stats.adding(gem.stats)
        }
        
        // 인챈트에서 스탯 추가
        for enchant in enchantments {
            stats = stats.adding(enchant.stats)
        }
        
        return stats
    }
    
    func getDisplayName() -> String {
        var displayName = customName ?? name
        
        // 강화 수치 표시
        if enhancementLevel > 0 {
            displayName = "+\(enhancementLevel) \(displayName)"
        }
        
        return displayName
    }
    
    func getQualityColor() -> ItemQualityColor {
        // 등급과 희귀도를 조합해서 색상 결정
        if rarity == .legendary {
            return .legendary
        } else if rarity == .epic {
            return .epic
        } else if enhancementLevel >= 7 {
            return .masterwork
        } else if enhancementLevel >= 4 {
            return .superior
        } else {
            switch grade {
            case .legendary: return .legendary
            case .rare: return .rare
            case .advanced: return .uncommon
            case .intermediate: return .common
            case .common: return .poor
            }
        }
    }
}

// MARK: - 지원 구조체들
struct RequiredStats: Codable, Equatable {
    let strength: Int
    let intelligence: Int
    let charisma: Int
    let luck: Int
    
    init(strength: Int = 0, intelligence: Int = 0, charisma: Int = 0, luck: Int = 0) {
        self.strength = strength
        self.intelligence = intelligence
        self.charisma = charisma
        self.luck = luck
    }
}

struct ItemStats: Codable, Equatable {
    var strength: Int = 0
    var intelligence: Int = 0
    var charisma: Int = 0
    var luck: Int = 0
    var tradingSkill: Int = 0
    var negotiationSkill: Int = 0
    var appraisalSkill: Int = 0
    
    func adding(_ other: ItemStats) -> ItemStats {
        return ItemStats(
            strength: self.strength + other.strength,
            intelligence: self.intelligence + other.intelligence,
            charisma: self.charisma + other.charisma,
            luck: self.luck + other.luck,
            tradingSkill: self.tradingSkill + other.tradingSkill,
            negotiationSkill: self.negotiationSkill + other.negotiationSkill,
            appraisalSkill: self.appraisalSkill + other.appraisalSkill
        )
    }
}

struct EnhancementStats: Codable, Equatable {
    let bonusStats: ItemStats
    let specialAbilities: [String]
    let visualEffects: [String]
}

struct SocketGem: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let type: GemType
    let stats: ItemStats
    let visualEffect: String?
    
    enum GemType: String, CaseIterable, Codable {
        case ruby = "루비"        // 힘 증가
        case sapphire = "사파이어"  // 지능 증가
        case emerald = "에메랄드"   // 매력 증가
        case diamond = "다이아몬드"  // 행운 증가
        case pearl = "진주"        // 거래 기술 증가
    }
}

struct Enchantment: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let type: EnchantmentType
    let stats: ItemStats
    let description: String
    let visualEffect: String?
    
    enum EnchantmentType: String, CaseIterable, Codable {
        case blessing = "축복"
        case curse = "저주"
        case enhancement = "강화"
        case protection = "보호"
        case luck = "행운"
    }
}

struct MagicalProperty: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let type: MagicType
    let stats: ItemStats
    let description: String
    let rarity: ItemRarity
    
    enum MagicType: String, CaseIterable, Codable {
        case elemental = "원소"
        case statBoost = "능력치"
        case skillBoost = "기술"
        case special = "특수"
        case aura = "오라"
    }
}

struct SpecialEffect: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let effectType: EffectType
    let value: Double
    let duration: TimeInterval?
    
    enum EffectType: String, CaseIterable, Codable {
        case priceDiscount = "가격할인"
        case experienceBonus = "경험치보너스"
        case luckBonus = "행운보너스"
        case speedBoost = "속도증가"
        case protectionBarrier = "보호막"
        case manaRegeneration = "마나회복"
        case goldFind = "골드발견"
        case rareItemFind = "희귀아이템발견"
    }
}

enum ItemRarity: String, CaseIterable, Codable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    case mythic = "mythic"  // 새로 추가
    
    var displayName: String {
        switch self {
        case .common: return "일반"
        case .uncommon: return "고급"
        case .rare: return "희귀"
        case .epic: return "영웅"
        case .legendary: return "전설"
        case .mythic: return "신화"
        }
    }
    
    var color: ItemQualityColor {
        switch self {
        case .common: return .common
        case .uncommon: return .uncommon
        case .rare: return .rare
        case .epic: return .epic
        case .legendary: return .legendary
        case .mythic: return .mythic
        }
    }
}

enum EquipmentSlot: String, CaseIterable, Codable {
    case helmet = "helmet"
    case armor = "armor"
    case weapon = "weapon"
    case accessory = "accessory"
    case tool = "tool"
    case consumable = "consumable"
}

enum ItemQualityColor: CaseIterable {
    case poor, common, uncommon, rare, epic, legendary, mythic, masterwork, superior
    
    var color: SwiftUI.Color {
        switch self {
        case .poor: return .gray
        case .common: return .primary
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        case .mythic: return .red
        case .masterwork: return .yellow
        case .superior: return .cyan
        }
    }
}

// MARK: - 서버 응답 모델
struct ServerItemResponse: Codable {
    let id: String
    let name: String
    let category: String
    let subcategory: String?
    let grade: String
    let rarity: String
    let requiredLicense: Int
    let requiredLevel: Int
    let requiredStats: RequiredStats?
    let basePrice: Int
    let currentPrice: Int?
    let marketValue: Int?
    let purchasePrice: Int?
    let weight: Double
    let durability: Int?
    let currentDurability: Int?
    let maxStack: Int
    let isStackable: Bool
    let isConsumable: Bool
    let isTradeable: Bool
    let isDropable: Bool
    let enhancementLevel: Int
    let enhancementStats: EnhancementStats?
    let socketGems: [SocketGem]?
    let enchantments: [Enchantment]?
    let customName: String?
    let magicalProperties: [MagicalProperty]?
    let specialEffects: [SpecialEffect]?
    let iconId: Int
    let spriteId: Int?
    let colorScheme: String?
    let description: String
    let loreText: String?
    let quantity: Int
    let isEquipped: Bool
    let equipmentSlot: EquipmentSlot?
    let isLocked: Bool
    let isFavorite: Bool
    let acquiredAt: TimeInterval
    let lastUsed: TimeInterval?
}
