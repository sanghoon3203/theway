// 📁 Models/SkillEffect.swift - 스킬 효과 시스템
import Foundation

// MARK: - SkillEffect 모델
struct SkillEffect: Identifiable, Codable {
    let id = UUID()
    let skillId: String
    let effectType: EffectType
    let value: Double
    let duration: TimeInterval?
    let startTime: Date
    var isActive: Bool { 
        guard let duration = duration else { return true }
        return Date().timeIntervalSince(startTime) < duration
    }
    
    enum EffectType: String, Codable, CaseIterable {
        // 거래 관련
        case tradingBonus = "trading_bonus"
        case negotiationBonus = "negotiation_bonus"
        case priceDiscount = "price_discount"
        case sellPriceBonus = "sell_price_bonus"
        
        // 스탯 보너스
        case strengthBonus = "strength_bonus"
        case intelligenceBonus = "intelligence_bonus"
        case charismaBonus = "charisma_bonus"
        case luckBonus = "luck_bonus"
        
        // 특수 효과
        case experienceBonus = "experience_bonus"
        case rareItemBonus = "rare_item_bonus"
        case inventoryExpansion = "inventory_expansion"
        case fastTravel = "fast_travel"
    }
}

// MARK: - SkillEffectManager
class SkillEffectManager: ObservableObject {
    @Published var player: Player
    
    init(player: Player) {
        self.player = player
    }
    
    // 스킬 효과 적용
    func applySkillEffect(_ effect: SkillEffect) {
        player.activeSkillEffects.append(effect)
        recalculatePlayerStats()
    }
    
    // 만료된 효과들 제거
    func removeExpiredEffects() {
        player.activeSkillEffects.removeAll { !$0.isActive }
        recalculatePlayerStats()
    }
    
    // 특정 효과 제거
    func removeEffect(withId effectId: UUID) {
        player.activeSkillEffects.removeAll { $0.id == effectId }
        recalculatePlayerStats()
    }
    
    // 플레이어 스탯 재계산
    private func recalculatePlayerStats() {
        // 활성 효과들만 필터링
        let activeEffects = player.activeSkillEffects.filter { $0.isActive }
        
        // 각 효과 타입별 보너스 계산
        for effect in activeEffects {
            switch effect.effectType {
            case .tradingBonus:
                // 거래 기술 보너스는 실시간 계산에서 적용
                break
            case .negotiationBonus:
                // 협상 보너스는 협상 시에 적용
                break
            case .strengthBonus:
                // 스탯 보너스는 임시적이므로 별도 처리 필요
                break
            case .intelligenceBonus:
                break
            case .charismaBonus:
                break
            case .luckBonus:
                break
            case .experienceBonus:
                // 경험치 보너스는 경험치 획득 시 적용
                break
            case .rareItemBonus:
                // 희귀 아이템 보너스는 아이템 발견 시 적용
                break
            case .inventoryExpansion:
                // 인벤토리 확장은 즉시 적용
                updateInventorySize()
            case .priceDiscount, .sellPriceBonus:
                // 가격 관련 보너스는 거래 시 적용
                break
            case .fastTravel:
                // 빠른 이동은 이동 시 적용
                break
            }
        }
    }
    
    // 인벤토리 크기 업데이트
    private func updateInventorySize() {
        let expansionBonus = player.activeSkillEffects
            .filter { $0.isActive && $0.effectType == .inventoryExpansion }
            .reduce(0) { $0 + Int($1.value) }
        
        // 기본 인벤토리 크기 + 스킬 보너스
        let baseSize = 5 + (player.level - 1) * 2 // 레벨당 2개씩 증가
        player.maxInventorySize = baseSize + expansionBonus
    }
    
    // 거래 성공률 계산
    func getTradingSuccessRate() -> Double {
        let baseRate = Double(player.tradingSkill) * 0.1
        let skillBonus = player.activeSkillEffects
            .filter { $0.isActive && $0.effectType == .tradingBonus }
            .reduce(0) { $0 + $1.value }
        
        return min(baseRate + skillBonus, 1.0) // 최대 100%
    }
    
    // 협상 보너스 계산
    func getNegotiationBonus() -> Double {
        let baseBonus = Double(player.negotiationSkill) * 0.05
        let skillBonus = player.activeSkillEffects
            .filter { $0.isActive && $0.effectType == .negotiationBonus }
            .reduce(0) { $0 + $1.value }
        
        return baseBonus + skillBonus
    }
    
    // 가격 할인 계산
    func getPriceDiscount() -> Double {
        let charismaBonus = Double(player.charisma) * 0.01
        let skillBonus = player.activeSkillEffects
            .filter { $0.isActive && $0.effectType == .priceDiscount }
            .reduce(0) { $0 + $1.value }
        
        return min(charismaBonus + skillBonus, 0.3) // 최대 30% 할인
    }
    
    // 판매 가격 보너스 계산
    func getSellPriceBonus() -> Double {
        let intelligenceBonus = Double(player.intelligence) * 0.01
        let skillBonus = player.activeSkillEffects
            .filter { $0.isActive && $0.effectType == .sellPriceBonus }
            .reduce(0) { $0 + $1.value }
        
        return min(intelligenceBonus + skillBonus, 0.5) // 최대 50% 보너스
    }
    
    // 경험치 보너스 계산
    func getExperienceMultiplier() -> Double {
        let baseMultiplier = 1.0
        let skillBonus = player.activeSkillEffects
            .filter { $0.isActive && $0.effectType == .experienceBonus }
            .reduce(0) { $0 + $1.value }
        
        return baseMultiplier + skillBonus
    }
    
    // 희귀 아이템 발견율 보너스
    func getRareItemBonus() -> Double {
        let luckBonus = Double(player.luck) * 0.01
        let skillBonus = player.activeSkillEffects
            .filter { $0.isActive && $0.effectType == .rareItemBonus }
            .reduce(0) { $0 + $1.value }
        
        return luckBonus + skillBonus
    }
    
    // 임시 스탯 보너스 계산
    func getTemporaryStatBonus(for statType: StatType) -> Int {
        let effectType: SkillEffect.EffectType
        switch statType {
        case .strength: effectType = .strengthBonus
        case .intelligence: effectType = .intelligenceBonus
        case .charisma: effectType = .charismaBonus
        case .luck: effectType = .luckBonus
        }
        
        let bonus = player.activeSkillEffects
            .filter { $0.isActive && $0.effectType == effectType }
            .reduce(0) { $0 + Int($1.value) }
        
        return bonus
    }
    
    enum StatType {
        case strength, intelligence, charisma, luck
    }
}

// MARK: - 스킬 효과 생성 헬퍼
extension SkillEffect {
    // 기본 거래 스킬 효과
    static func basicTradingEffect() -> SkillEffect {
        SkillEffect(
            skillId: "basic_trading",
            effectType: .tradingBonus,
            value: 0.1, // 10% 보너스
            duration: nil, // 영구 효과
            startTime: Date()
        )
    }
    
    // 고급 협상 스킬 효과
    static func advancedNegotiationEffect() -> SkillEffect {
        SkillEffect(
            skillId: "advanced_negotiation",
            effectType: .negotiationBonus,
            value: 0.15, // 15% 보너스
            duration: nil,
            startTime: Date()
        )
    }
    
    // 시장 예측 스킬 효과
    static func marketPredictionEffect() -> SkillEffect {
        SkillEffect(
            skillId: "market_prediction",
            effectType: .priceDiscount,
            value: 0.05, // 5% 추가 할인
            duration: nil,
            startTime: Date()
        )
    }
    
    // 마스터 상인 스킬 효과 (복합 효과)
    static func masterTraderEffects() -> [SkillEffect] {
        [
            SkillEffect(
                skillId: "master_trader",
                effectType: .tradingBonus,
                value: 0.2, // 20% 보너스
                duration: nil,
                startTime: Date()
            ),
            SkillEffect(
                skillId: "master_trader",
                effectType: .sellPriceBonus,
                value: 0.2, // 20% 판매 보너스
                duration: nil,
                startTime: Date()
            ),
            SkillEffect(
                skillId: "master_trader",
                effectType: .rareItemBonus,
                value: 0.1, // 10% 희귀 아이템 보너스
                duration: nil,
                startTime: Date()
            )
        ]
    }
    
    // 임시 행운 물약 효과
    static func luckPotionEffect() -> SkillEffect {
        SkillEffect(
            skillId: "luck_potion",
            effectType: .luckBonus,
            value: 5, // +5 행운
            duration: 30 * 60, // 30분
            startTime: Date()
        )
    }
}