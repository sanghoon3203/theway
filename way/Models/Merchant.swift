// 📁 Models/Merchant.swift - 오류 수정된 버전
import Foundation
import CoreLocation
import SwiftUI

struct Merchant: Identifiable, Codable {
    let id: String
    
    // 기본 정보
    let name: String
    let title: String?
    let type: MerchantType
    let personality: MerchantPersonality
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    
    // 거래 관련
    let requiredLicense: LicenseLevel
    var inventory: [TradeItem]
    let priceModifier: Double
    let negotiationDifficulty: Int // 1-5 (1이 쉬움)
    
    // 선호도 시스템
    let preferredItems: [String] // 카테고리 배열
    let dislikedItems: [String]  // 카테고리 배열
    let reputationRequirement: Int
    
    // 관계 시스템
    var friendshipLevel: Int
    var trustLevel: Int
    var totalTrades: Int
    var totalSpent: Int
    var lastInteraction: Date?
    var relationshipStatus: RelationshipStatus
    
    // 외형 및 UI
    let appearanceId: Int
    let portraitId: Int
    
    // 상태 시스템
    var isActive: Bool
    var mood: MerchantMood
    var lastRestocked: Date
    
    // 대화 시스템
    var dialogues: [MerchantDialogue]
    var currentDialogue: MerchantDialogue?
    
    // 특수 능력 및 서비스
    let specialAbilities: [SpecialAbility]
    let services: [MerchantService]
    let isQuestGiver: Bool
    
    // MARK: - 초기화
    init(
        id: String = UUID().uuidString,
        name: String,
        title: String? = nil,
        type: MerchantType,
        personality: MerchantPersonality = .friendly,
        district: SeoulDistrict,
        coordinate: CLLocationCoordinate2D,
        requiredLicense: LicenseLevel,
        inventory: [TradeItem] = [],
        priceModifier: Double = 1.0,
        negotiationDifficulty: Int = 3,
        preferredItems: [String] = [],
        dislikedItems: [String] = [],
        reputationRequirement: Int = 0,
        friendshipLevel: Int = 0,
        trustLevel: Int = 0,
        totalTrades: Int = 0,
        totalSpent: Int = 0,
        appearanceId: Int = 1,
        portraitId: Int = 1,
        isActive: Bool = true,
        mood: MerchantMood = .neutral,
        specialAbilities: [SpecialAbility] = [],
        services: [MerchantService] = [],
        isQuestGiver: Bool = false
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.type = type
        self.personality = personality
        self.district = district
        self.coordinate = coordinate
        self.requiredLicense = requiredLicense
        self.inventory = inventory
        self.priceModifier = priceModifier
        self.negotiationDifficulty = negotiationDifficulty
        self.preferredItems = preferredItems
        self.dislikedItems = dislikedItems
        self.reputationRequirement = reputationRequirement
        self.friendshipLevel = friendshipLevel
        self.trustLevel = trustLevel
        self.totalTrades = totalTrades
        self.totalSpent = totalSpent
        self.lastInteraction = nil
        self.relationshipStatus = .stranger
        self.appearanceId = appearanceId
        self.portraitId = portraitId
        self.isActive = isActive
        self.mood = mood
        self.lastRestocked = Date()
        self.dialogues = []
        self.currentDialogue = nil
        self.specialAbilities = specialAbilities
        self.services = services
        self.isQuestGiver = isQuestGiver
    }
    
    // MARK: - 서버 응답용 초기화
    init(from serverMerchant: ServerMerchantResponse) {
        self.id = serverMerchant.id
        self.name = serverMerchant.name
        self.title = serverMerchant.title
        self.type = MerchantType(rawValue: serverMerchant.type) ?? .retail
        self.personality = MerchantPersonality(rawValue: serverMerchant.personality) ?? .friendly
        self.district = SeoulDistrict(rawValue: serverMerchant.district) ?? .gangnam
        self.coordinate = CLLocationCoordinate2D(
            latitude: serverMerchant.location.lat,
            longitude: serverMerchant.location.lng
        )
        self.requiredLicense = LicenseLevel(rawValue: serverMerchant.requiredLicense) ?? .beginner
        self.inventory = serverMerchant.inventory.map { TradeItem(from: $0) }
        self.priceModifier = serverMerchant.priceModifier
        self.negotiationDifficulty = serverMerchant.negotiationDifficulty
        self.preferredItems = serverMerchant.preferredItems ?? []
        self.dislikedItems = serverMerchant.dislikedItems ?? []
        self.reputationRequirement = serverMerchant.reputationRequirement
        self.friendshipLevel = serverMerchant.friendshipLevel
        self.trustLevel = serverMerchant.trustLevel
        self.totalTrades = serverMerchant.totalTrades
        self.totalSpent = serverMerchant.totalSpent
        self.lastInteraction = serverMerchant.lastInteraction.map { Date(timeIntervalSince1970: $0) }
        self.relationshipStatus = RelationshipStatus(rawValue: serverMerchant.relationshipStatus) ?? .stranger
        self.appearanceId = serverMerchant.appearanceId
        self.portraitId = serverMerchant.portraitId
        self.isActive = serverMerchant.isActive
        self.mood = MerchantMood(rawValue: serverMerchant.mood) ?? .neutral
        self.lastRestocked = Date(timeIntervalSince1970: serverMerchant.lastRestocked)
        self.dialogues = serverMerchant.dialogues?.map { MerchantDialogue(from: $0) } ?? []
        self.currentDialogue = nil
        self.specialAbilities = serverMerchant.specialAbilities?.map { SpecialAbility(rawValue: $0) ?? .appraisal } ?? []
        self.services = serverMerchant.services?.map { MerchantService(from: $0) } ?? []
        self.isQuestGiver = serverMerchant.isQuestGiver
    }
    
    // MARK: - 메서드들
    func canTrade(with player: Player) -> Bool {
        // 라이센스 체크
        guard player.currentLicense.rawValue >= requiredLicense.rawValue else { return false }
        
        // 평판 체크
        guard player.reputation >= reputationRequirement else { return false }
        
        // 활성 상태 체크
        guard isActive else { return false }
        
        return true
    }
    
    func getFinalPrice(for item: TradeItem, player: Player) -> Int {
        var finalPrice = Double(item.currentPrice)
        
        // 기본 가격 수정자 적용
        finalPrice *= priceModifier
        
        // 우호도에 따른 할인
        let friendshipDiscount = min(Double(friendshipLevel) * 0.01, 0.2) // 최대 20% 할인
        finalPrice *= (1.0 - friendshipDiscount)
        
        // 선호 아이템 할인
        if preferredItems.contains(item.category) {
            finalPrice *= 0.9 // 10% 할인
        }
        
        // 비선호 아이템 할증
        if dislikedItems.contains(item.category) {
            finalPrice *= 1.2 // 20% 할증
        }
        
        // 기분에 따른 가격 변동
        finalPrice *= mood.priceMultiplier
        
        return max(Int(finalPrice), 1) // 최소 1원
    }
    
    mutating func updateRelationship(with player: Player, tradeAmount: Int) {
        // 거래 정보 업데이트
        totalTrades += 1
        totalSpent += tradeAmount
        lastInteraction = Date()
        
        // 친밀도 증가 (거래 금액에 비례)
        let friendshipGain = max(1, tradeAmount / 10000) // 만원당 1포인트
        friendshipLevel += friendshipGain
        
        // 신뢰도 증가
        trustLevel += 1
        
        // 관계 상태 업데이트
        updateRelationshipStatus()
        
        // 기분 개선
        if mood == .angry || mood == .grumpy {
            mood = .neutral
        } else if mood == .neutral && friendshipLevel > 50 {
            mood = .happy
        }
    }
    
    private mutating func updateRelationshipStatus() {
        if friendshipLevel >= 100 {
            relationshipStatus = .bestFriend
        } else if friendshipLevel >= 50 {
            relationshipStatus = .friend
        } else if friendshipLevel >= 20 {
            relationshipStatus = .acquaintance
        } else if totalTrades >= 5 {
            relationshipStatus = .regular
        } else {
            relationshipStatus = .stranger
        }
    }
    
    func getDialogue(for situation: DialogueSituation, player: Player) -> MerchantDialogue? {
        // 조건에 맞는 대사 필터링
        let availableDialogues = dialogues.filter { dialogue in
            dialogue.dialogueType == situation &&
            dialogue.checkCondition(player: player, merchant: self)
        }
        
        // 우선순위가 높은 대사 선택
        return availableDialogues.sorted { $0.priority > $1.priority }.first
    }
    
    func canUseService(_ serviceType: ServiceType, player: Player) -> Bool {
        guard let service = services.first(where: { $0.serviceType == serviceType }) else {
            return false
        }
        
        return service.canUse(player: player, merchant: self)
    }
    
    func hasSpecialAbility(_ ability: SpecialAbility) -> Bool {
        return specialAbilities.contains(ability)
    }
}

// MARK: - Enums and Supporting Types

// ✅ 수정된 MerchantType
enum MerchantType: String, CaseIterable, Codable {
    case retail = "retail"           // 말단상인
    case wholesale = "wholesale"     // 중간상인
    case premium = "premium"         // 중요대상인
    case artisan = "artisan"         // 장인
    case mystic = "mystic"          // 신비상인
    case collector = "collector"     // 수집가
    
    var displayName: String {
        switch self {
        case .retail: return "말단상인"
        case .wholesale: return "중간상인"
        case .premium: return "중요상인"
        case .artisan: return "장인"
        case .mystic: return "신비상인"
        case .collector: return "수집가"
        }
    }
    
    var maxItemGrade: ItemGrade {
        switch self {
        case .retail: return .intermediate
        case .wholesale: return .rare
        case .premium, .artisan: return .legendary
        case .mystic, .collector: return .legendary
        }
    }
}

// ✅ 추가된 MerchantPersonality
enum MerchantPersonality: String, CaseIterable, Codable {
    case friendly = "friendly"       // 친화적
    case greedy = "greedy"          // 탐욕적
    case mysterious = "mysterious"   // 신비로운
    case wise = "wise"              // 현명한
    case cheerful = "cheerful"      // 쾌활한
    case serious = "serious"        // 진지한
    case eccentric = "eccentric"    // 괴짜
    
    var personalityDisplayName: String {
        switch self {
        case .friendly: return "친화적"
        case .greedy: return "탐욕적"
        case .mysterious: return "신비로운"
        case .wise: return "현명한"
        case .cheerful: return "쾌활한"
        case .serious: return "진지한"
        case .eccentric: return "괴짜"
        }
    }
}

enum MerchantMood: String, CaseIterable, Codable {
    case happy = "happy"
    case neutral = "neutral"
    case grumpy = "grumpy"
    case angry = "angry"
    case excited = "excited"
    case sad = "sad"
    case mysterious = "mysterious"
    case wise = "wise"
    case greedy = "greedy"
    case friendly = "friendly"
    
    var moodDisplayName: String {
        switch self {
        case .happy: return "기분 좋음"
        case .neutral: return "보통"
        case .grumpy: return "기분 나쁨"
        case .angry: return "화남"
        case .excited: return "신남"
        case .sad: return "슬픔"
        case .mysterious: return "알 수 없음"
        case .wise: return "현명함"
        case .greedy: return "욕심부림"
        case .friendly: return "친근함"
        }
    }
    
    var priceMultiplier: Double {
        switch self {
        case .happy: return 0.95        // 5% 할인
        case .neutral: return 1.0       // 정상가
        case .grumpy: return 1.05       // 5% 할증
        case .angry: return 1.15        // 15% 할증
        case .excited: return 0.9       // 10% 할인
        case .sad: return 1.02          // 2% 할증
        case .mysterious: return 1.0    // 정상가
        case .wise: return 0.98         // 2% 할인 (현명한 거래)
        case .greedy: return 1.1        // 10% 할증 (욕심)
        case .friendly: return 0.93     // 7% 할인 (친근함)
        }
    }
    
    var icon: String {
        switch self {
        case .happy: return "face.smiling"
        case .neutral: return "face.dashed"
        case .grumpy: return "face.frowning"
        case .angry: return "flame"
        case .excited: return "star.fill"
        case .sad: return "cloud.rain"
        case .mysterious: return "questionmark"
        case .wise: return "brain.head.profile"
        case .greedy: return "dollarsign.circle"
        case .friendly: return "heart.circle"
        }
    }
}

enum RelationshipStatus: String, CaseIterable, Codable {
    case stranger = "stranger"
    case regular = "regular"
    case acquaintance = "acquaintance"
    case friend = "friend"
    case bestFriend = "bestFriend"
    case rival = "rival"
    case enemy = "enemy"
    
    var relationshipDisplayName: String {
        switch self {
        case .stranger: return "낯선 사람"
        case .regular: return "단골"
        case .acquaintance: return "아는 사이"
        case .friend: return "친구"
        case .bestFriend: return "절친"
        case .rival: return "경쟁자"
        case .enemy: return "적"
        }
    }
    
    var color: SwiftUI.Color {
        switch self {
        case .stranger: return .gray
        case .regular: return .blue
        case .acquaintance: return .green
        case .friend: return .cyan
        case .bestFriend: return .yellow
        case .rival: return .orange
        case .enemy: return .red
        }
    }
}

enum SpecialAbility: String, CaseIterable, Codable {
    case appraisal = "appraisal"                    // 감정
    case enhancement = "enhancement"                // 강화
    case enchantment = "enchantment"               // 인챈트
    case repair = "repair"                         // 수리
    case gemSetting = "gem_setting"                // 젬 세팅
    case fortuneTelling = "fortune_telling"        // 점술
    case itemIdentification = "item_identification" // 아이템 식별
    case priceManipulation = "price_manipulation"  // 가격 조작
    case rareItemSummoning = "rare_item_summoning" // 희귀 아이템 소환
    case teleportation = "teleportation"           // 순간이동
    
    var displayName: String {
        switch self {
        case .appraisal: return "아이템 감정"
        case .enhancement: return "아이템 강화"
        case .enchantment: return "마법 부여"
        case .repair: return "아이템 수리"
        case .gemSetting: return "젬 세팅"
        case .fortuneTelling: return "운세 점술"
        case .itemIdentification: return "미지 아이템 식별"
        case .priceManipulation: return "가격 흥정"
        case .rareItemSummoning: return "희귀템 소환"
        case .teleportation: return "순간이동 서비스"
        }
    }
    
    var description: String {
        switch self {
        case .appraisal: return "아이템의 정확한 가치를 평가해드립니다"
        case .enhancement: return "아이템을 강화하여 능력치를 향상시킵니다"
        case .enchantment: return "아이템에 마법 속성을 부여합니다"
        case .repair: return "손상된 아이템을 수리합니다"
        case .gemSetting: return "아이템에 젬을 세팅합니다"
        case .fortuneTelling: return "미래의 거래 운을 점쳐드립니다"
        case .itemIdentification: return "정체불명의 아이템을 식별합니다"
        case .priceManipulation: return "특별한 가격으로 거래할 수 있습니다"
        case .rareItemSummoning: return "희귀한 아이템을 특별히 구해드립니다"
        case .teleportation: return "원하는 위치로 즉시 이동시켜드립니다"
        }
    }
    
    var cost: Int {
        switch self {
        case .appraisal: return 1000
        case .enhancement: return 5000
        case .enchantment: return 10000
        case .repair: return 2000
        case .gemSetting: return 3000
        case .fortuneTelling: return 500
        case .itemIdentification: return 2500
        case .priceManipulation: return 0
        case .rareItemSummoning: return 50000
        case .teleportation: return 10000
        }
    }
}

// MARK: - 대화 시스템
struct MerchantDialogue: Identifiable, Codable {
    let id = UUID()
    let dialogueType: DialogueSituation
    let conditionType: DialogueCondition?
    let conditionValue: String?
    let dialogueText: String
    let moodRequired: MerchantMood?
    let priority: Int
    let isActive: Bool
    
    init(
        dialogueType: DialogueSituation,
        conditionType: DialogueCondition? = nil,
        conditionValue: String? = nil,
        dialogueText: String,
        moodRequired: MerchantMood? = nil,
        priority: Int = 1,
        isActive: Bool = true
    ) {
        self.dialogueType = dialogueType
        self.conditionType = conditionType
        self.conditionValue = conditionValue
        self.dialogueText = dialogueText
        self.moodRequired = moodRequired
        self.priority = priority
        self.isActive = isActive
    }
    
    init(from serverDialogue: ServerDialogueResponse) {
        self.dialogueType = DialogueSituation(rawValue: serverDialogue.dialogueType) ?? .greeting
        self.conditionType = serverDialogue.conditionType.flatMap { DialogueCondition(rawValue: $0) }
        self.conditionValue = serverDialogue.conditionValue
        self.dialogueText = serverDialogue.dialogueText
        self.moodRequired = serverDialogue.moodRequired.flatMap { MerchantMood(rawValue: $0) }
        self.priority = serverDialogue.priority
        self.isActive = serverDialogue.isActive
    }
    
    func checkCondition(player: Player, merchant: Merchant) -> Bool {
        // 기분 조건 체크
        if let requiredMood = moodRequired, merchant.mood != requiredMood {
            return false
        }
        
        // 활성 상태 체크
        guard isActive else { return false }
        
        // 추가 조건 체크
        guard let condition = conditionType, let value = conditionValue else {
            return true // 조건이 없으면 통과
        }
        
        switch condition {
        case .reputation:
            return player.reputation >= Int(value) ?? 0
        case .friendship:
            return merchant.friendshipLevel >= Int(value) ?? 0
        case .level:
            return player.level >= Int(value) ?? 0
        case .money:
            return player.money >= Int(value) ?? 0
        case .timeOfDay:
            let hour = Calendar.current.component(.hour, from: Date())
            return value.contains(String(hour))
        case .itemInInventory:
            return player.inventory.contains { $0.itemId == value }
        }
    }
}

enum DialogueSituation: String, CaseIterable, Codable {
    case greeting = "greeting"
    case tradeStart = "trade_start"
    case tradeSuccess = "trade_success"
    case tradeFail = "trade_fail"
    case farewell = "farewell"
    case special = "special"
    case angry = "angry"
    case happy = "happy"
    case questOffer = "quest_offer"
    case questComplete = "quest_complete"
    
    var situationDisplayName: String {
        switch self {
        case .greeting: return "인사"
        case .tradeStart: return "거래 시작"
        case .tradeSuccess: return "거래 성공"
        case .tradeFail: return "거래 실패"
        case .farewell: return "작별"
        case .special: return "특별"
        case .angry: return "화남"
        case .happy: return "기쁨"
        case .questOffer: return "퀘스트 제안"
        case .questComplete: return "퀘스트 완료"
        }
    }
}

enum DialogueCondition: String, CaseIterable, Codable {
    case reputation = "reputation"
    case friendship = "friendship"
    case level = "level"
    case money = "money"
    case timeOfDay = "time_of_day"
    case itemInInventory = "item_in_inventory"
}

// MARK: - 서비스 시스템
struct MerchantService: Identifiable, Codable {
    let id = UUID()
    let serviceType: ServiceType
    let serviceName: String
    let description: String
    let baseCost: Int
    let costFormula: String?
    let requiredFriendship: Int
    let requiredReputation: Int
    let successRate: Double
    let cooldownHours: Int
    let isAvailable: Bool
    
    init(from serverService: ServerServiceResponse) {
        self.serviceType = ServiceType(rawValue: serverService.serviceType) ?? .appraisal
        self.serviceName = serverService.serviceName
        self.description = serverService.description
        self.baseCost = serverService.baseCost
        self.costFormula = serverService.costFormula
        self.requiredFriendship = serverService.requiredFriendship
        self.requiredReputation = serverService.requiredReputation
        self.successRate = serverService.successRate
        self.cooldownHours = serverService.cooldownHours
        self.isAvailable = serverService.isAvailable
    }
    
    func canUse(player: Player, merchant: Merchant) -> Bool {
        return isAvailable &&
               merchant.friendshipLevel >= requiredFriendship &&
               player.reputation >= requiredReputation
    }
    
    func calculateCost(for item: TradeItem?) -> Int {
        // 기본 비용부터 시작
        var cost = baseCost
        
        // 아이템 기반 비용 계산 (있는 경우)
        if let item = item {
            switch serviceType {
            case .enhancement:
                cost = item.basePrice / 10 + (item.enhancementLevel * 1000)
            case .repair:
                cost = max(item.basePrice / 20, 100)
            case .appraisal:
                cost = max(item.basePrice / 100, 50)
            case .enchantment:
                cost = item.basePrice / 5
            case .gemSetting:
                cost = item.basePrice / 15
            case .identification:
                cost = 1000
            case .storage, .teleport, .quest, .training:
                cost = baseCost
            }
        }
        
        return cost
    }
}

enum ServiceType: String, CaseIterable, Codable {
    case appraisal = "appraisal"
    case enhancement = "enhancement"
    case repair = "repair"
    case enchantment = "enchantment"
    case gemSetting = "gem_setting"
    case identification = "identification"
    case storage = "storage"
    case teleport = "teleport"
    case quest = "quest"
    case training = "training"
    
    var displayName: String {
        switch self {
        case .appraisal: return "아이템 감정"
        case .enhancement: return "아이템 강화"
        case .repair: return "아이템 수리"
        case .enchantment: return "마법 부여"
        case .gemSetting: return "젬 세팅"
        case .identification: return "아이템 식별"
        case .storage: return "창고 서비스"
        case .teleport: return "순간이동"
        case .quest: return "퀘스트"
        case .training: return "기술 훈련"
        }
    }
}

// MARK: - 서버 응답 모델들 (LocationData 중복 제거)
struct MerchantLocationData: Codable {
    let lat: Double
    let lng: Double
}

struct ServerMerchantResponse: Codable {
    let id: String
    let name: String
    let title: String?
    let type: String
    let personality: String
    let district: String
    let location: MerchantLocationData
    let requiredLicense: Int
    let inventory: [ServerItemResponse]
    let priceModifier: Double
    let negotiationDifficulty: Int
    let preferredItems: [String]?
    let dislikedItems: [String]?
    let reputationRequirement: Int
    let friendshipLevel: Int
    let trustLevel: Int
    let totalTrades: Int
    let totalSpent: Int
    let lastInteraction: TimeInterval?
    let relationshipStatus: String
    let appearanceId: Int
    let portraitId: Int
    let isActive: Bool
    let mood: String
    let lastRestocked: TimeInterval
    let dialogues: [ServerDialogueResponse]?
    let specialAbilities: [String]?
    let services: [ServerServiceResponse]?
    let isQuestGiver: Bool
}

struct ServerDialogueResponse: Codable {
    let dialogueType: String
    let conditionType: String?
    let conditionValue: String?
    let dialogueText: String
    let moodRequired: String?
    let priority: Int
    let isActive: Bool
}

struct ServerServiceResponse: Codable {
    let serviceType: String
    let serviceName: String
    let description: String
    let baseCost: Int
    let costFormula: String?
    let requiredFriendship: Int
    let requiredReputation: Int
    let successRate: Double
    let cooldownHours: Int
    let isAvailable: Bool
}
