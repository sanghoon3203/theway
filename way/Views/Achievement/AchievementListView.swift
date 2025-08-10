// 📁 Views/Achievement/AchievementListView.swift - 업적 목록 화면
import SwiftUI

struct AchievementListView: View {
    @StateObject private var viewModel = AchievementViewModel()
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showCompletedOnly = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.oceanWave
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 필터 섹션
                    filterSection
                    
                    // 업적 목록
                    achievementsList
                }
            }
            .navigationTitle("업적")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadAchievements()
            }
            .alert("업적 완료!", isPresented: $viewModel.showCompletionAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                if let newAchievement = viewModel.newlyCompletedAchievement {
                    Text("'\(newAchievement.name)' 업적을 달성했습니다!\n\(newAchievement.rewardInfo?.displayText ?? "")")
                }
            }
        }
    }
    
    // MARK: - 필터 섹션
    private var filterSection: some View {
        VStack(spacing: 12) {
            // 카테고리 필터
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryFilterButton(
                        title: "전체",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(AchievementCategory.allCases, id: \.rawValue) { category in
                        CategoryFilterButton(
                            title: category.displayName,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // 완료된 업적만 보기 토글
            HStack {
                Toggle("완료된 업적만 보기", isOn: $showCompletedOnly)
                    .font(.merchantBody)
                    .foregroundColor(.dialogueText)
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient.parchmentGlow)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.dialogueBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    // MARK: - 업적 목록
    private var achievementsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredAchievements) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        onClaimReward: { achievementId in
                            viewModel.claimReward(for: achievementId)
                        }
                    )
                }
                
                if filteredAchievements.isEmpty {
                    EmptyAchievementsView()
                }
            }
            .padding()
        }
    }
    
    // MARK: - 계산된 속성
    private var filteredAchievements: [Achievement] {
        viewModel.achievements.filter { achievement in
            // 카테고리 필터
            if let selectedCategory = selectedCategory,
               achievement.category != selectedCategory {
                return false
            }
            
            // 완료 상태 필터
            if showCompletedOnly && !achievement.isCompleted {
                return false
            }
            
            return true
        }
    }
}

// MARK: - CategoryFilterButton 컴포넌트
struct CategoryFilterButton: View {
    let title: String
    let icon: String?
    let color: Color?
    let isSelected: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        color: Color? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                
                Text(title)
                    .font(.compassSmall)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? (color ?? .compass) : Color.parchmentBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? (color ?? .compass) : Color.dialogueBorder, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? .white : .dialogueText)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - AchievementCard 컴포넌트
struct AchievementCard: View {
    let achievement: Achievement
    let onClaimReward: (String) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // 업적 아이콘
            achievementIcon
            
            // 업적 정보
            VStack(alignment: .leading, spacing: 8) {
                // 업적 이름과 카테고리
                HStack {
                    Text(achievement.name)
                        .font(.merchantBody)
                        .foregroundColor(.dialogueText)
                    
                    Spacer()
                    
                    Text(achievement.category.displayName)
                        .font(.compassSmall)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(achievement.category.color.opacity(0.2))
                        )
                        .foregroundColor(achievement.category.color)
                }
                
                // 업적 설명
                Text(achievement.description)
                    .font(.compassSmall)
                    .foregroundColor(.mistGray)
                    .lineLimit(2)
                
                // 진행도 바
                progressBar
                
                // 보상 정보
                if let reward = achievement.rewardInfo {
                    Text("보상: \(reward.displayText)")
                        .font(.compassSmall)
                        .foregroundColor(.treasureGold)
                }
            }
            
            // 상태 및 액션 버튼
            actionButton
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient.parchmentGlow)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(achievement.isCompleted ? Color.expGreen : Color.dialogueBorder, lineWidth: 2)
                )
        )
    }
    
    private var achievementIcon: some View {
        ZStack {
            Circle()
                .fill(achievement.category.color.opacity(0.2))
                .frame(width: 50, height: 50)
            
            Image(systemName: achievement.category.icon)
                .font(.system(size: 24))
                .foregroundColor(achievement.category.color)
                .opacity(achievement.isCompleted ? 1.0 : 0.6)
            
            if achievement.isCompleted {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.expGreen)
                            .background(Color.white.clipShape(Circle()))
                    }
                }
                .frame(width: 50, height: 50)
            }
        }
    }
    
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(achievement.progressText)
                    .font(.compassSmall)
                    .foregroundColor(.dialogueText)
                
                Spacer()
                
                Text("\(Int(achievement.progressPercentage * 100))%")
                    .font(.compassSmall)
                    .foregroundColor(achievement.isCompleted ? .expGreen : .mistGray)
            }
            
            ProgressView(value: achievement.progressPercentage)
                .tint(achievement.isCompleted ? .expGreen : .compass)
                .scaleEffect(y: 2.0)
        }
    }
    
    private var actionButton: some View {
        Group {
            if achievement.canClaim {
                Button("보상 받기") {
                    onClaimReward(achievement.id)
                }
                .buttonStyle(TreasureButtonStyle())
                .controlSize(.small)
            } else if achievement.isCompleted && achievement.claimed {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.expGreen)
                    Text("완료")
                        .font(.compassSmall)
                        .foregroundColor(.expGreen)
                }
            } else {
                VStack {
                    Image(systemName: "clock")
                        .font(.system(size: 20))
                        .foregroundColor(.mistGray)
                    Text("진행중")
                        .font(.compassSmall)
                        .foregroundColor(.mistGray)
                }
            }
        }
    }
}

// MARK: - EmptyAchievementsView 컴포넌트
struct EmptyAchievementsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.mistGray)
            
            Text("해당하는 업적이 없습니다")
                .font(.merchantBody)
                .foregroundColor(.dialogueText)
            
            Text("다른 카테고리를 선택하거나 더 많은 게임을 플레이해보세요!")
                .font(.compassSmall)
                .foregroundColor(.mistGray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

// MARK: - Preview
#Preview {
    AchievementListView()
}