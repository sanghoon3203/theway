// 📁 Views/Achievement/AchievementView.swift - 업적 시스템 메인 화면
import SwiftUI

struct AchievementView: View {
    @ObservedObject var achievementManager: AchievementManager
    @State private var selectedCategory: AchievementCategory = .all
    @State private var showUnclaimedOnly = false
    
    enum AchievementCategory: String, CaseIterable {
        case all = "전체"
        case trading = "거래"
        case exploration = "탐험"
        case social = "사회"
        case collection = "수집"
        case combat = "전투"
        
        var icon: String {
            switch self {
            case .all: return "star.fill"
            case .trading: return "cart.fill"
            case .exploration: return "map.fill"
            case .social: return "person.2.fill"
            case .collection: return "bag.fill"
            case .combat: return "shield.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .treasureGold
            case .trading: return .goldYellow
            case .exploration: return .seaBlue
            case .social: return .expGreen
            case .collection: return .manaBlue
            case .combat: return .compass
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.oceanWave
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 헤더 (업적 통계)
                    achievementHeader
                    
                    // 필터 및 카테고리 선택
                    filterSection
                    
                    // 업적 리스트
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAchievements) { achievement in
                                AchievementCard(
                                    achievement: achievement,
                                    onClaim: { claimedAchievement in
                                        achievementManager.claimReward(claimedAchievement)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("업적")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 업적 헤더
    private var achievementHeader: some View {
        VStack(spacing: 16) {
            // 전체 진행률
            VStack(spacing: 8) {
                HStack {
                    Text("전체 진행률")
                        .font(.navigatorTitle)
                        .foregroundColor(.treasureGold)
                    
                    Spacer()
                    
                    Text("\(completedCount) / \(totalCount)")
                        .font(.statText)
                        .foregroundColor(.expGreen)
                }
                
                VStack {
                    Text("업적 완료")
                        .font(.compassSmall)
                        .foregroundColor(.dialogueText)
                }
                .statBar(
                    current: Double(completedCount),
                    maximum: Double(totalCount),
                    color: .expGreen
                )
            }
            
            // 통계 카드들
            HStack(spacing: 12) {
                StatCard(
                    title: "완료",
                    value: "\(completedCount)",
                    icon: "checkmark.circle.fill",
                    color: .expGreen
                )
                
                StatCard(
                    title: "진행 중",
                    value: "\(inProgressCount)",
                    icon: "clock.fill",
                    color: .goldYellow
                )
                
                StatCard(
                    title: "미획득",
                    value: "\(unclaimedCount)",
                    icon: "gift.fill",
                    color: .compass
                )
            }
        }
        .parchmentCard()
        .padding()
    }
    
    // MARK: - 필터 섹션
    private var filterSection: some View {
        VStack(spacing: 12) {
            // 카테고리 선택
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 미수령 필터
            Toggle("미수령 업적만 표시", isOn: $showUnclaimedOnly)
                .font(.merchantBody)
                .foregroundColor(.dialogueText)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.parchment.opacity(0.3))
    }
    
    // MARK: - 계산된 속성들
    private var filteredAchievements: [Achievement] {
        var filtered = achievementManager.achievements
        
        // 카테고리 필터
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category.rawValue == selectedCategory.rawValue }
        }
        
        // 미수령 필터
        if showUnclaimedOnly {
            filtered = filtered.filter { $0.isCompleted && !$0.isClaimed }
        }
        
        return filtered.sorted { first, second in
            // 미수령 업적을 맨 위로
            if first.isCompleted && !first.isClaimed && !(second.isCompleted && !second.isClaimed) {
                return true
            }
            if second.isCompleted && !second.isClaimed && !(first.isCompleted && !first.isClaimed) {
                return false
            }
            
            // 완료된 업적을 그 다음으로
            if first.isCompleted && !second.isCompleted {
                return true
            }
            if second.isCompleted && !first.isCompleted {
                return false
            }
            
            // 진행률 순으로
            return first.progressPercentage > second.progressPercentage
        }
    }
    
    private var totalCount: Int { achievementManager.achievements.count }
    private var completedCount: Int { achievementManager.achievements.filter { $0.isCompleted }.count }
    private var inProgressCount: Int { achievementManager.achievements.filter { !$0.isCompleted && $0.currentProgress > 0 }.count }
    private var unclaimedCount: Int { achievementManager.achievements.filter { $0.isCompleted && !$0.isClaimed }.count }
}

// MARK: - CategoryButton 컴포넌트
struct CategoryButton: View {
    let category: AchievementView.AchievementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.rawValue)
                    .font(.compassSmall)
            }
        }
        .buttonStyle(JRPGMenuButtonStyle(isSelected: isSelected))
    }
}

// MARK: - StatCard 컴포넌트
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.statText)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.compassSmall)
                    .foregroundColor(.mistGray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Achievement 모델
struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: AchievementCategoryModel
    let conditionType: String
    let targetValue: Int
    var currentProgress: Int = 0
    var isCompleted: Bool { currentProgress >= targetValue }
    var isClaimed: Bool = false
    let rewardType: String
    let rewardValue: String
    let iconId: Int
    let isHidden: Bool
    let createdAt: Date
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return isCompleted ? 1.0 : 0.0 }
        return min(Double(currentProgress) / Double(targetValue), 1.0)
    }
    
    enum AchievementCategoryModel: String, Codable {
        case trading, exploration, social, collection, combat
    }
}

// MARK: - AchievementManager
class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var unclaimedRewards: [Achievement] = []
    
    init() {
        loadInitialAchievements()
    }
    
    private func loadInitialAchievements() {
        achievements = [
            Achievement(
                id: "first_trade",
                name: "첫 거래",
                description: "첫 번째 거래를 완료하세요",
                category: .trading,
                conditionType: "trade_count",
                targetValue: 1,
                currentProgress: 0,
                rewardType: "exp",
                rewardValue: "50",
                iconId: 1,
                isHidden: false,
                createdAt: Date()
            ),
            Achievement(
                id: "money_maker_1",
                name: "돈벌이 초보",
                description: "10만원을 벌어보세요",
                category: .trading,
                conditionType: "money_earned",
                targetValue: 100000,
                currentProgress: 45000,
                rewardType: "money",
                rewardValue: "5000",
                iconId: 2,
                isHidden: false,
                createdAt: Date()
            ),
            Achievement(
                id: "collector_1",
                name: "수집가",
                description: "10개의 서로 다른 아이템을 수집하세요",
                category: .collection,
                conditionType: "unique_items",
                targetValue: 10,
                currentProgress: 7,
                rewardType: "cosmetic",
                rewardValue: "collector_badge",
                iconId: 3,
                isHidden: false,
                createdAt: Date()
            ),
            Achievement(
                id: "explorer_1",
                name: "서울 탐험가",
                description: "5개 구역에서 거래하세요",
                category: .exploration,
                conditionType: "districts_visited",
                targetValue: 5,
                currentProgress: 5,
                isClaimed: false,
                rewardType: "title",
                rewardValue: "탐험가",
                iconId: 4,
                isHidden: false,
                createdAt: Date()
            )
        ]
    }
    
    func checkAchievement(_ type: String, value: Int) {
        // TODO: 실제 업적 체크 로직
        for index in achievements.indices {
            if achievements[index].conditionType == type && !achievements[index].isCompleted {
                achievements[index].currentProgress = min(value, achievements[index].targetValue)
            }
        }
    }
    
    func claimReward(_ achievement: Achievement) {
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            achievements[index].isClaimed = true
            // TODO: 실제 보상 지급 로직
        }
    }
}

// MARK: - Preview
#Preview {
    AchievementView(achievementManager: AchievementManager())
}