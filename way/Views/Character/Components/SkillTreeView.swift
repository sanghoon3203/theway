// 📁 Views/Character/Components/SkillTreeView.swift - 스킬 트리 시스템
import SwiftUI

struct SkillTreeView: View {
    @Binding var player: Player
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: SkillCategory = .trading
    @State private var availableSkillPoints: Int
    @State private var selectedSkill: GameSkill?
    @State private var showSkillDetail = false
    
    enum SkillCategory: String, CaseIterable {
        case trading = "거래"
        case social = "사회"
        case exploration = "탐험"
        case combat = "전투"
        
        var icon: String {
            switch self {
            case .trading: return "cart.fill"
            case .social: return "person.2.fill"
            case .exploration: return "map.fill"
            case .combat: return "shield.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .trading: return .treasureGold
            case .social: return .expGreen
            case .exploration: return .seaBlue
            case .combat: return .compass
            }
        }
    }
    
    init(player: Binding<Player>) {
        self._player = player
        self._availableSkillPoints = State(initialValue: player.wrappedValue.skillPoints)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.oceanWave
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 헤더
                    skillHeader
                    
                    // 카테고리 선택기
                    categorySelector
                    
                    // 스킬 트리 영역
                    ScrollView {
                        skillTreeContent
                            .padding()
                    }
                }
            }
            .navigationTitle("스킬 트리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("완료") {
                        dismiss()
                    }
                    .foregroundColor(.treasureGold)
                }
            }
        }
        .sheet(isPresented: $showSkillDetail) {
            if let skill = selectedSkill {
                SkillDetailSheet(
                    skill: skill,
                    canLearn: canLearnSkill(skill),
                    availablePoints: availableSkillPoints
                ) { learnedSkill in
                    learnSkill(learnedSkill)
                }
            }
        }
    }
    
    // MARK: - 스킬 헤더
    private var skillHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("사용 가능한 스킬 포인트")
                    .font(.merchantBody)
                    .foregroundColor(.dialogueText)
                
                Spacer()
                
                Text("\(availableSkillPoints)")
                    .font(.pirateTitle)
                    .foregroundColor(.manaBlue)
            }
            
            if availableSkillPoints == 0 {
                Text("레벨 업으로 스킬 포인트를 획득하세요")
                    .font(.compassSmall)
                    .foregroundColor(.mistGray)
            }
        }
        .parchmentCard()
        .padding()
    }
    
    // MARK: - 카테고리 선택기
    private var categorySelector: some View {
        HStack(spacing: 0) {
            ForEach(SkillCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 16))
                            .foregroundColor(selectedCategory == category ? category.color : .mistGray)
                        Text(category.rawValue)
                            .font(.compassSmall)
                            .foregroundColor(selectedCategory == category ? category.color : .mistGray)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    selectedCategory == category ?
                    RoundedRectangle(cornerRadius: 12)
                        .fill(category.color.opacity(0.2)) :
                    nil
                )
            }
        }
        .padding(.horizontal)
        .background(Color.parchment.opacity(0.7))
    }
    
    // MARK: - 스킬 트리 콘텐츠
    @ViewBuilder
    private var skillTreeContent: some View {
        switch selectedCategory {
        case .trading:
            tradingSkillTree
        case .social:
            socialSkillTree
        case .exploration:
            explorationSkillTree
        case .combat:
            combatSkillTree
        }
    }
    
    // MARK: - 거래 스킬 트리
    private var tradingSkillTree: some View {
        VStack(spacing: 20) {
            // Tier 1 스킬들
            SkillTier(title: "기초 거래 기술") {
                HStack(spacing: 16) {
                    SkillNode(
                        skill: GameSkill.basicTrading,
                        isUnlocked: true,
                        isLearned: hasSkill(.basicTrading),
                        canLearn: canLearnSkill(.basicTrading)
                    ) {
                        selectSkill(.basicTrading)
                    }
                    
                    SkillNode(
                        skill: GameSkill.priceAnalysis,
                        isUnlocked: true,
                        isLearned: hasSkill(.priceAnalysis),
                        canLearn: canLearnSkill(.priceAnalysis)
                    ) {
                        selectSkill(.priceAnalysis)
                    }
                }
            }
            
            // 연결선
            SkillConnection()
            
            // Tier 2 스킬들
            SkillTier(title: "중급 거래 기술") {
                HStack(spacing: 16) {
                    SkillNode(
                        skill: GameSkill.advancedNegotiation,
                        isUnlocked: hasSkill(.basicTrading),
                        isLearned: hasSkill(.advancedNegotiation),
                        canLearn: canLearnSkill(.advancedNegotiation)
                    ) {
                        selectSkill(.advancedNegotiation)
                    }
                    
                    SkillNode(
                        skill: GameSkill.marketPrediction,
                        isUnlocked: hasSkill(.priceAnalysis),
                        isLearned: hasSkill(.marketPrediction),
                        canLearn: canLearnSkill(.marketPrediction)
                    ) {
                        selectSkill(.marketPrediction)
                    }
                }
            }
            
            // 연결선
            SkillConnection()
            
            // Tier 3 스킬들
            SkillTier(title: "마스터 거래 기술") {
                SkillNode(
                    skill: GameSkill.masterTrader,
                    isUnlocked: hasSkill(.advancedNegotiation) && hasSkill(.marketPrediction),
                    isLearned: hasSkill(.masterTrader),
                    canLearn: canLearnSkill(.masterTrader)
                ) {
                    selectSkill(.masterTrader)
                }
            }
        }
    }
    
    // MARK: - 다른 스킬 트리들 (간소화된 버전)
    private var socialSkillTree: some View {
        VStack(spacing: 20) {
            Text("사회 스킬 트리 (준비 중)")
                .font(.merchantBody)
                .foregroundColor(.mistGray)
            
            Text("상인과의 관계, 길드 관리 등의 스킬이 추가됩니다")
                .font(.compassSmall)
                .foregroundColor(.dialogueText)
                .multilineTextAlignment(.center)
        }
        .parchmentCard()
    }
    
    private var explorationSkillTree: some View {
        VStack(spacing: 20) {
            Text("탐험 스킬 트리 (준비 중)")
                .font(.merchantBody)
                .foregroundColor(.mistGray)
            
            Text("지도 제작, 숨겨진 상인 발견 등의 스킬이 추가됩니다")
                .font(.compassSmall)
                .foregroundColor(.dialogueText)
                .multilineTextAlignment(.center)
        }
        .parchmentCard()
    }
    
    private var combatSkillTree: some View {
        VStack(spacing: 20) {
            Text("전투 스킬 트리 (준비 중)")
                .font(.merchantBody)
                .foregroundColor(.mistGray)
            
            Text("해적 퇴치, 호위 등의 스킬이 추가됩니다")
                .font(.compassSmall)
                .foregroundColor(.dialogueText)
                .multilineTextAlignment(.center)
        }
        .parchmentCard()
    }
    
    // MARK: - 메서드들
    private func selectSkill(_ skill: GameSkill) {
        selectedSkill = skill
        showSkillDetail = true
    }
    
    private func hasSkill(_ skill: GameSkill) -> Bool {
        return player.learnedSkills.contains(skill.name)
    }
    
    private func canLearnSkill(_ skill: GameSkill) -> Bool {
        return availableSkillPoints >= skill.cost && !hasSkill(skill)
    }
    
    private func learnSkill(_ skill: GameSkill) {
        availableSkillPoints -= skill.cost
        
        // 플레이어에 스킬 추가
        player.learnedSkills.insert(skill.name)
        player.skillPoints = availableSkillPoints
        
        // 스킬 효과 적용
        applySkillEffects(for: skill)
    }
    
    private func applySkillEffects(for skill: GameSkill) {
        let skillEffectManager = SkillEffectManager(player: player)
        
        switch skill.name {
        case "기본 거래":
            skillEffectManager.applySkillEffect(.basicTradingEffect())
            
        case "고급 협상":
            skillEffectManager.applySkillEffect(.advancedNegotiationEffect())
            
        case "시장 예측":
            skillEffectManager.applySkillEffect(.marketPredictionEffect())
            
        case "마스터 상인":
            let effects = SkillEffect.masterTraderEffects()
            for effect in effects {
                skillEffectManager.applySkillEffect(effect)
            }
            
        default:
            break
        }
    }
}

// MARK: - GameSkill 모델
struct GameSkill: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let effect: String
    let cost: Int
    let icon: String
    let color: Color
    let prerequisites: [GameSkill]
    
    static let basicTrading = GameSkill(
        name: "기본 거래",
        description: "기본적인 거래 기술을 익힙니다",
        effect: "거래 성공률 +10%",
        cost: 1,
        icon: "cart",
        color: .treasureGold,
        prerequisites: []
    )
    
    static let priceAnalysis = GameSkill(
        name: "가격 분석",
        description: "아이템의 적정 가격을 분석합니다",
        effect: "아이템 가치 정보 표시",
        cost: 1,
        icon: "chart.line.uptrend.xyaxis",
        color: .seaBlue,
        prerequisites: []
    )
    
    static let advancedNegotiation = GameSkill(
        name: "고급 협상",
        description: "더 나은 가격으로 협상할 수 있습니다",
        effect: "협상 성공률 +15%, 최대 할인 +5%",
        cost: 2,
        icon: "person.2",
        color: .expGreen,
        prerequisites: [basicTrading]
    )
    
    static let marketPrediction = GameSkill(
        name: "시장 예측",
        description: "미래의 가격 변동을 예측합니다",
        effect: "가격 트렌드 예측 정보 제공",
        cost: 2,
        icon: "brain",
        color: .manaBlue,
        prerequisites: [priceAnalysis]
    )
    
    static let masterTrader = GameSkill(
        name: "마스터 상인",
        description: "모든 거래 기술의 정점에 도달합니다",
        effect: "모든 거래 관련 보너스 +20%",
        cost: 3,
        icon: "crown",
        color: .compass,
        prerequisites: [advancedNegotiation, marketPrediction]
    )
}

// MARK: - 스킬 트리 컴포넌트들
struct SkillTier<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.merchantBody)
                .foregroundColor(.treasureGold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            content
        }
    }
}

struct SkillNode: View {
    let skill: GameSkill
    let isUnlocked: Bool
    let isLearned: Bool
    let canLearn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: skill.icon)
                    .font(.system(size: 24))
                    .foregroundColor(nodeColor)
                
                Text(skill.name)
                    .font(.compassSmall)
                    .foregroundColor(nodeColor)
                    .multilineTextAlignment(.center)
                
                if isLearned {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.expGreen)
                }
            }
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(nodeBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(nodeBorderColor, lineWidth: 2)
                )
        )
        .disabled(!isUnlocked || isLearned)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
    
    private var nodeColor: Color {
        if isLearned {
            return .expGreen
        } else if canLearn {
            return skill.color
        } else {
            return .mistGray
        }
    }
    
    private var nodeBackgroundColor: Color {
        if isLearned {
            return Color.expGreen.opacity(0.2)
        } else if canLearn {
            return skill.color.opacity(0.1)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var nodeBorderColor: Color {
        if isLearned {
            return .expGreen
        } else if canLearn {
            return skill.color
        } else {
            return .mistGray
        }
    }
}

struct SkillConnection: View {
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(Color.mistGray.opacity(0.5))
                    .frame(width: 4, height: 4)
            }
        }
    }
}

// MARK: - 스킬 상세 정보 시트
struct SkillDetailSheet: View {
    let skill: GameSkill
    let canLearn: Bool
    let availablePoints: Int
    let onLearn: (GameSkill) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 스킬 아이콘과 이름
                VStack(spacing: 16) {
                    Image(systemName: skill.icon)
                        .font(.system(size: 60))
                        .foregroundColor(skill.color)
                    
                    Text(skill.name)
                        .font(.pirateTitle)
                        .foregroundColor(.treasureGold)
                }
                
                // 스킬 정보
                VStack(alignment: .leading, spacing: 12) {
                    Text("설명")
                        .font(.merchantBody)
                        .foregroundColor(.treasureGold)
                    
                    Text(skill.description)
                        .font(.dialogueText)
                        .foregroundColor(.dialogueText)
                    
                    Text("효과")
                        .font(.merchantBody)
                        .foregroundColor(.treasureGold)
                    
                    Text(skill.effect)
                        .font(.dialogueText)
                        .foregroundColor(.expGreen)
                    
                    HStack {
                        Text("필요 스킬 포인트:")
                            .font(.merchantBody)
                            .foregroundColor(.dialogueText)
                        
                        Text("\(skill.cost)")
                            .font(.statText)
                            .foregroundColor(.manaBlue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // 액션 버튼
                if canLearn {
                    Button("스킬 습득") {
                        onLearn(skill)
                        dismiss()
                    }
                    .buttonStyle(TreasureButtonStyle())
                } else {
                    Text("스킬 포인트가 부족하거나 선행 조건을 만족하지 않습니다")
                        .font(.compassSmall)
                        .foregroundColor(.mistGray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .dialogueBox()
            .background(LinearGradient.oceanWave)
            .navigationTitle("스킬 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SkillTreeView(player: .constant(Player()))
}