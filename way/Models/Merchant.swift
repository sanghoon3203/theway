// 📁 Models/Merchant.swift - 확장된 상인 시스템
import Foundation
import CoreLocation

struct Merchant: Identifiable {
    let id: String
    let name: String
    let title: String?  // 칭호 ("현명한", "탐욕스러운" 등)
    let type: MerchantType
    let personality: MerchantPersonality
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    let requiredLicense: LicenseLevel
    
    // 외형 정보
    let appearanceId: Int
    let portraitId: Int
    
    // 거래 특성
    let priceModifier: Double    // 가격 조정 비율 (0.8 = 20% 할인)
    let negotiationDifficulty: Int  // 협상 난이도 (1-5)
    let preferredItems: [ItemCategory]  // 선호하는 아이템 카테고리
    let dislikedItems: [ItemCategory]   // 싫어하는 아이템 카테고리
    
    // 관계 시스템
    let reputationRequirement: Int  // 거래에 필요한 평판
    var friendshipLevel: Int
    
    // 상태 정보
    var inventory: [MerchantItem]
    var trustLevel: Int
    var isActive: Bool
    var currentMood: MerchantMood
    var lastRestocked: Date
    
    // 특별 기능
    let specialAbilities: [MerchantAbility]
    let isQuestGiver: Bool
    
    // 현재 이벤트/무드 효과 (나중에 추가 예정)
    // var activeMoodEvents: [MerchantMoodEvent] = []
    
    // 표시용 이름 (칭호 포함)
    var displayName: String {
        if let title = title {
            return "\(title) \(name)"
        }
        return name
    }
    
    // 현재 가격 보정 계산
    var currentPriceModifier: Double {
        var modifier = priceModifier
        
        // 기분에 따른 보정
        modifier *= currentMood.priceModifier
        
        // TODO: 활성 이벤트 보정 (나중에 구현)
        // for event in activeMoodEvents where event.isActive {
        //     modifier *= event.priceModifier
        // }
        
        return modifier
    }
    
    // 협상 가능 여부
    func canNegotiate(with player: Player) -> Bool {
        // 평판 요구사항 체크
        guard player.trustPoints >= reputationRequirement else { return false }
        
        // 기분이 매우 나쁘면 협상 거부
        if currentMood == .angry || currentMood == .furious {
            return false
        }
        
        return true
    }
    
    // 아이템 선호도 체크
    func getItemPreference(for item: TradeItem) -> ItemPreference {
        if preferredItems.contains(item.category) {
            return .preferred
        } else if dislikedItems.contains(item.category) {
            return .disliked
        }
        return .neutral
    }
    
    // 최종 아이템 가격 계산
    func calculatePrice(for item: TradeItem, player: Player, isPlayerSelling: Bool) -> Int {
        var price = item.currentPrice
        
        // 기본 상인 가격 보정
        if isPlayerSelling {
            price = Int(Double(price) * 0.8) // 판매 시 80%
        }
        
        // 상인 가격 보정
        price = Int(Double(price) * currentPriceModifier)
        
        // 아이템 선호도 보정
        let preference = getItemPreference(for: item)
        switch preference {
        case .preferred:
            price = Int(Double(price) * (isPlayerSelling ? 1.2 : 0.9))
        case .disliked:
            price = Int(Double(price) * (isPlayerSelling ? 0.8 : 1.3))
        case .neutral:
            break
        }
        
        // 플레이어와의 관계 보정
        if let relation = player.merchantRelations[id] {
            let relationshipBonus = min(Double(relation.friendshipLevel) * 0.02, 0.2) // 최대 20% 할인
            if isPlayerSelling {
                price = Int(Double(price) * (1.0 + relationshipBonus))
            } else {
                price = Int(Double(price) * (1.0 - relationshipBonus))
            }
        }
        
        return max(price, 1) // 최소 1원
    }
    
    // 재고 보충
    mutating func restockInventory() {
        lastRestocked = Date()
        
        // 기본 아이템들 재보충 로직
        for i in inventory.indices {
            if inventory[i].stock < inventory[i].maxStock / 2 {
                inventory[i].stock = min(inventory[i].stock + inventory[i].restockAmount, inventory[i].maxStock)
            }
        }
    }
}

// MARK: - 상인 유형
enum MerchantType: String, CaseIterable, Codable {
    case retail = "retail"      // 소매상
    case artisan = "artisan"    // 장인
    case collector = "collector" // 수집가
    case mystic = "mystic"      // 신비한 상인
    
    var displayName: String {
        switch self {
        case .retail: return "소매상"
        case .artisan: return "장인"
        case .collector: return "수집가"
        case .mystic: return "신비한 상인"
        }
    }
    
    var description: String {
        switch self {
        case .retail: return "일반적인 아이템을 판매하는 상인"
        case .artisan: return "직접 제작한 특별한 아이템을 판매"
        case .collector: return "희귀하고 특별한 아이템을 수집"
        case .mystic: return "마법적이고 신비로운 아이템을 거래"
        }
    }
    
    var preferredCategories: [ItemCategory] {
        switch self {
        case .retail: return [.modern, .food, .consumable]
        case .artisan: return [.weapon, .armor, .accessory]
        case .collector: return [.artifact, .material]
        case .mystic: return [.potion, .artifact, .material]
        }
    }
}

// MARK: - 상인 성격
enum MerchantPersonality: String, CaseIterable, Codable {
    case friendly = "friendly"      // 친근한
    case greedy = "greedy"          // 탐욕스러운
    case mysterious = "mysterious"   // 신비로운
    case grumpy = "grumpy"          // 심술궂은
    case wise = "wise"              // 현명한
    case eccentric = "eccentric"    // 괴짜
    
    var displayName: String {
        switch self {
        case .friendly: return "친근한"
        case .greedy: return "탐욕스러운"
        case .mysterious: return "신비로운"
        case .grumpy: return "심술궂은"
        case .wise: return "현명한"
        case .eccentric: return "괴짜"
        }
    }
    
    var defaultMood: MerchantMood {
        switch self {
        case .friendly: return .happy
        case .greedy: return .neutral
        case .mysterious: return .calm
        case .grumpy: return .annoyed
        case .wise: return .calm
        case .eccentric: return .excited
        }
    }
    
    var negotiationModifier: Double {
        switch self {
        case .friendly: return 0.8      // 20% 쉬움
        case .greedy: return 1.3        // 30% 어려움
        case .mysterious: return 1.1    // 10% 어려움
        case .grumpy: return 1.2        // 20% 어려움
        case .wise: return 1.0          // 보통
        case .eccentric: return 0.9     // 10% 쉬움
        }
    }
}

// MARK: - 상인 기분
enum MerchantMood: String, CaseIterable, Codable {
    case furious = "furious"        // 격노
    case angry = "angry"            // 화남
    case annoyed = "annoyed"        // 짜증
    case neutral = "neutral"        // 보통
    case content = "content"        // 만족
    case happy = "happy"            // 기쁨
    case excited = "excited"        // 흥분
    case calm = "calm"              // 차분함
    
    var displayName: String {
        switch self {
        case .furious: return "격노"
        case .angry: return "화남"
        case .annoyed: return "짜증"
        case .neutral: return "보통"
        case .content: return "만족"
        case .happy: return "기쁨"
        case .excited: return "흥분"
        case .calm: return "차분함"
        }
    }
    
    var priceModifier: Double {
        switch self {
        case .furious: return 1.5       // 50% 비쌈
        case .angry: return 1.3         // 30% 비쌈
        case .annoyed: return 1.1       // 10% 비쌈
        case .neutral: return 1.0       // 보통
        case .content: return 0.95      // 5% 할인
        case .happy: return 0.9         // 10% 할인
        case .excited: return 0.85      // 15% 할인
        case .calm: return 1.0          // 보통
        }
    }
    
    var color: String {
        switch self {
        case .furious: return "red"
        case .angry: return "orange"
        case .annoyed: return "yellow"
        case .neutral: return "gray"
        case .content: return "green"
        case .happy: return "blue"
        case .excited: return "purple"
        case .calm: return "cyan"
        }
    }
    
    var iconName: String {
        switch self {
        case .furious: return "flame.fill"
        case .angry: return "exclamationmark.triangle.fill"
        case .annoyed: return "minus.circle.fill"
        case .neutral: return "circle.fill"
        case .content: return "checkmark.circle.fill"
        case .happy: return "face.smiling.fill"
        case .excited: return "star.fill"
        case .calm: return "leaf.fill"
        }
    }
}

// MARK: - 아이템 선호도
enum ItemPreference: String, CaseIterable, Codable {
    case preferred = "preferred"    // 선호
    case neutral = "neutral"        // 보통
    case disliked = "disliked"      // 싫어함
    
    var displayName: String {
        switch self {
        case .preferred: return "선호"
        case .neutral: return "보통"
        case .disliked: return "싫어함"
        }
    }
    
    var color: String {
        switch self {
        case .preferred: return "green"
        case .neutral: return "gray"
        case .disliked: return "red"
        }
    }
}

// MARK: - 상인 아이템
struct MerchantItem: Identifiable, Codable {
    let id: String
    let itemId: String  // item_master 참조
    let name: String
    let category: ItemCategory
    let basePrice: Int
    var currentPrice: Int
    let rarity: ItemRarity
    var stock: Int
    let maxStock: Int
    let restockAmount: Int
    
    var isInStock: Bool {
        return stock > 0
    }
    
    var stockStatus: StockStatus {
        let ratio = Double(stock) / Double(maxStock)
        switch ratio {
        case 0.0: return .outOfStock
        case 0.01...0.3: return .low
        case 0.31...0.7: return .medium
        default: return .high
        }
    }
    
    enum StockStatus: String, CaseIterable {
        case outOfStock = "품절"
        case low = "부족"
        case medium = "보통"
        case high = "충분"
        
        var color: String {
            switch self {
            case .outOfStock: return "red"
            case .low: return "orange"
            case .medium: return "yellow"
            case .high: return "green"
            }
        }
    }
}

// MARK: - 상인 특수 능력
enum MerchantAbility: String, CaseIterable, Codable {
    case appraisal = "appraisal"                    // 감정
    case repair = "repair"                          // 수리
    case enhancement = "enhancement"                // 강화
    case enchantment = "enchantment"               // 인챈트
    case storage = "storage"                       // 창고
    case transport = "transport"                   // 운송
    case fortuneTelling = "fortune_telling"        // 점술
    case alchemyBrewing = "alchemy_brewing"        // 연금술
    case techUpgrade = "tech_upgrade"              // 기술 업그레이드
    case ancientKnowledge = "ancient_knowledge"    // 고대 지식
    
    var displayName: String {
        switch self {
        case .appraisal: return "감정"
        case .repair: return "수리"
        case .enhancement: return "강화"
        case .enchantment: return "인챈트"
        case .storage: return "창고"
        case .transport: return "운송"
        case .fortuneTelling: return "점술"
        case .alchemyBrewing: return "연금술"
        case .techUpgrade: return "기술 업그레이드"
        case .ancientKnowledge: return "고대 지식"
        }
    }
    
    var description: String {
        switch self {
        case .appraisal: return "아이템의 진짜 가치를 알려줍니다"
        case .repair: return "손상된 아이템을 수리해줍니다"
        case .enhancement: return "아이템을 강화해줍니다"
        case .enchantment: return "아이템에 마법을 부여합니다"
        case .storage: return "아이템을 보관해줍니다"
        case .transport: return "다른 지역으로 아이템을 운송해줍니다"
        case .fortuneTelling: return "미래의 시세를 점쳐줍니다"
        case .alchemyBrewing: return "재료로 물약을 제조해줍니다"
        case .techUpgrade: return "현대 아이템을 업그레이드해줍니다"
        case .ancientKnowledge: return "고대 아이템에 대한 지식을 제공합니다"
        }
    }
    
    var iconName: String {
        switch self {
        case .appraisal: return "magnifyingglass"
        case .repair: return "hammer.fill"
        case .enhancement: return "arrow.up.circle.fill"
        case .enchantment: return "sparkles"
        case .storage: return "archivebox.fill"
        case .transport: return "truck.box.fill"
        case .fortuneTelling: return "crystal.ball.fill"
        case .alchemyBrewing: return "testtube.2"
        case .techUpgrade: return "gear"
        case .ancientKnowledge: return "book.closed.fill"
        }
    }
    
    var requiredFriendshipLevel: Int {
        switch self {
        case .appraisal: return 0
        case .repair: return 1
        case .enhancement: return 2
        case .enchantment: return 3
        case .storage: return 1
        case .transport: return 2
        case .fortuneTelling: return 3
        case .alchemyBrewing: return 4
        case .techUpgrade: return 3
        case .ancientKnowledge: return 5
        }
    }
}

// MARK: - 상인 기분 이벤트
struct MerchantMoodEvent: Identifiable, Codable {
    let id: String
    let eventType: EventType
    let moodChange: MerchantMood
    let priceModifier: Double
    let durationHours: Int
    let description: String
    let startTime: Date
    let endTime: Date
    
    var isActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
    
    var remainingTime: TimeInterval {
        return endTime.timeIntervalSinceNow
    }
    
    enum EventType: String, CaseIterable, Codable {
        case weather = "weather"        // 날씨
        case season = "season"          // 계절
        case marketCrash = "market_crash" // 시장 폭락
        case festival = "festival"      // 축제
        case random = "random"          // 무작위
        
        var displayName: String {
            switch self {
            case .weather: return "날씨"
            case .season: return "계절"
            case .marketCrash: return "시장 변동"
            case .festival: return "축제"
            case .random: return "특별 이벤트"
            }
        }
    }
}

// MARK: - 상인 대사 시스템
struct MerchantDialogue: Identifiable, Codable {
    let id: String
    let merchantId: String
    let dialogueType: DialogueType
    let conditionType: ConditionType?
    let conditionValue: String?
    let dialogueText: String
    let moodRequired: MerchantMood?
    let priority: Int
    let isActive: Bool
    
    enum DialogueType: String, CaseIterable, Codable {
        case greeting = "greeting"              // 인사
        case tradeStart = "trade_start"         // 거래 시작
        case tradeSuccess = "trade_success"     // 거래 성공
        case tradeFail = "trade_fail"           // 거래 실패
        case negotiationStart = "negotiation_start" // 협상 시작
        case negotiationSuccess = "negotiation_success" // 협상 성공
        case negotiationFail = "negotiation_fail"    // 협상 실패
        case farewell = "farewell"              // 작별
        case special = "special"                // 특별 상황
        case quest = "quest"                    // 퀘스트
        
        var displayName: String {
            switch self {
            case .greeting: return "인사"
            case .tradeStart: return "거래 시작"
            case .tradeSuccess: return "거래 성공"
            case .tradeFail: return "거래 실패"
            case .negotiationStart: return "협상 시작"
            case .negotiationSuccess: return "협상 성공"
            case .negotiationFail: return "협상 실패"
            case .farewell: return "작별"
            case .special: return "특별"
            case .quest: return "퀘스트"
            }
        }
    }
    
    enum ConditionType: String, CaseIterable, Codable {
        case reputation = "reputation"          // 평판
        case friendship = "friendship"          // 우정
        case time = "time"                     // 시간
        case weather = "weather"               // 날씨
        case itemType = "item_type"            // 아이템 타입
        case playerLevel = "player_level"      // 플레이어 레벨
        
        var displayName: String {
            switch self {
            case .reputation: return "평판"
            case .friendship: return "우정"
            case .time: return "시간"
            case .weather: return "날씨"
            case .itemType: return "아이템 타입"
            case .playerLevel: return "플레이어 레벨"
            }
        }
    }
}

// MARK: - 서버 데이터 파싱
extension Merchant {
    static func fromServerData(_ data: [String: Any]) -> Merchant? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let typeString = data["type"] as? String,
              let type = MerchantType(rawValue: typeString),
              let personalityString = data["personality"] as? String,
              let personality = MerchantPersonality(rawValue: personalityString),
              let districtString = data["district"] as? String,
              let district = SeoulDistrict(rawValue: districtString),
              let lat = data["location_lat"] as? Double,
              let lng = data["location_lng"] as? Double,
              let requiredLicenseInt = data["required_license"] as? Int,
              let requiredLicense = LicenseLevel(rawValue: requiredLicenseInt) else {
            return nil
        }
        
        // 인벤토리 파싱
        var inventory: [MerchantItem] = []
        if let inventoryString = data["inventory"] as? String,
           let inventoryData = inventoryString.data(using: .utf8),
           let inventoryArray = try? JSONSerialization.jsonObject(with: inventoryData) as? [[String: Any]] {
            inventory = inventoryArray.compactMap { MerchantItem.fromServerData($0) }
        }
        
        // 선호/비선호 아이템 파싱
        let preferredItems = parseItemCategories(data["preferred_items"])
        let dislikedItems = parseItemCategories(data["disliked_items"])
        
        // 특수 능력 파싱
        let specialAbilities = parseSpecialAbilities(data["special_abilities"])
        
        return Merchant(
            id: id,
            name: name,
            title: data["title"] as? String,
            type: type,
            personality: personality,
            district: district,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
            requiredLicense: requiredLicense,
            appearanceId: data["appearance_id"] as? Int ?? 1,
            portraitId: data["portrait_id"] as? Int ?? 1,
            priceModifier: data["price_modifier"] as? Double ?? 1.0,
            negotiationDifficulty: data["negotiation_difficulty"] as? Int ?? 3,
            preferredItems: preferredItems,
            dislikedItems: dislikedItems,
            reputationRequirement: data["reputation_requirement"] as? Int ?? 0,
            friendshipLevel: data["friendship_level"] as? Int ?? 0,
            inventory: inventory,
            trustLevel: data["trust_level"] as? Int ?? 0,
            isActive: data["is_active"] as? Bool ?? true,
            currentMood: MerchantMood(rawValue: data["mood"] as? String ?? "neutral") ?? personality.defaultMood,
            lastRestocked: parseDate(data["last_restocked"]) ?? Date(),
            specialAbilities: specialAbilities,
            isQuestGiver: data["quest_giver"] as? Bool ?? false
        )
    }
    
    private static func parseItemCategories(_ data: Any?) -> [ItemCategory] {
        guard let categoriesString = data as? String,
              let categoriesData = categoriesString.data(using: .utf8),
              let categoriesArray = try? JSONSerialization.jsonObject(with: categoriesData) as? [String] else {
            return []
        }
        
        return categoriesArray.compactMap { ItemCategory(rawValue: $0) }
    }
    
    private static func parseSpecialAbilities(_ data: Any?) -> [MerchantAbility] {
        guard let abilitiesString = data as? String,
              let abilitiesData = abilitiesString.data(using: .utf8),
              let abilitiesArray = try? JSONSerialization.jsonObject(with: abilitiesData) as? [String] else {
            return []
        }
        
        return abilitiesArray.compactMap { MerchantAbility(rawValue: $0) }
    }
    
    private static func parseDate(_ data: Any?) -> Date? {
        guard let dateString = data as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

extension MerchantItem {
    static func fromServerData(_ data: [String: Any]) -> MerchantItem? {
        guard let itemId = data["item_id"] as? String,
              let name = data["name"] as? String,
              let categoryString = data["category"] as? String,
              let category = ItemCategory(rawValue: categoryString),
              let price = data["price"] as? Int,
              let stock = data["stock"] as? Int else {
            return nil
        }
        
        return MerchantItem(
            id: UUID().uuidString,
            itemId: itemId,
            name: name,
            category: category,
            basePrice: price,
            currentPrice: price,
            rarity: ItemRarity(rawValue: data["rarity"] as? Int ?? 1) ?? .common,
            stock: stock,
            maxStock: data["max_stock"] as? Int ?? stock * 2,
            restockAmount: data["restock_amount"] as? Int ?? max(1, stock / 2)
        )
    }
}
