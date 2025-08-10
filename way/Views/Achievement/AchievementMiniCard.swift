// 📁 Views/Achievement/AchievementMiniCard.swift - 작은 업적 카드 (다른 화면에서 사용)
import SwiftUI

struct AchievementMiniCard: View {
    let achievement: Achievement
    let showProgress: Bool
    let onTap: (() -> Void)?
    
    init(
        achievement: Achievement, 
        showProgress: Bool = true,
        onTap: (() -> Void)? = nil
    ) {
        self.achievement = achievement
        self.showProgress = showProgress
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                // 업적 아이콘
                achievementIcon
                
                // 업적 정보
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(achievement.name)
                            .font(.compassBody)
                            .foregroundColor(.dialogueText)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if achievement.canClaim {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.treasureGold)
                        }
                    }
                    
                    if showProgress {
                        HStack(spacing: 8) {
                            ProgressBar(
                                current: achievement.currentProgress,
                                total: achievement.conditionValue
                            )
                            .frame(height: 6)
                            
                            Text(achievement.progressText)
                                .font(.compassSmall)
                                .foregroundColor(.mistGray)
                                .frame(minWidth: 40, alignment: .trailing)
                        }
                    } else {
                        Text(achievement.description)
                            .font(.compassSmall)
                            .foregroundColor(.mistGray)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient.parchmentBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                achievement.isCompleted ? Color.expGreen : Color.dialogueBorder,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
    }
    
    private var achievementIcon: some View {
        ZStack {
            Circle()
                .fill(achievement.category.color.opacity(0.2))
                .frame(width: 32, height: 32)
            
            Image(systemName: achievement.category.icon)
                .font(.system(size: 16))
                .foregroundColor(achievement.category.color)
                .opacity(achievement.isCompleted ? 1.0 : 0.6)
            
            if achievement.isCompleted {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.expGreen)
                            .background(Color.white.clipShape(Circle()))
                    }
                }
                .frame(width: 32, height: 32)
            }
        }
    }
}

// MARK: - AchievementNotification 컴포넌트 (새 업적 달성 시 표시)
struct AchievementNotification: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // 축하 아이콘
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.goldYellow)
                
                Text("업적 달성!")
                    .font(.navigatorTitle)
                    .foregroundColor(.treasureGold)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.goldYellow)
            }
            
            // 업적 정보
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(achievement.category.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.category.icon)
                        .font(.system(size: 30))
                        .foregroundColor(achievement.category.color)
                    
                    // 반짝이는 효과
                    Circle()
                        .stroke(Color.goldYellow, lineWidth: 2)
                        .frame(width: 70, height: 70)
                        .opacity(0.6)
                        .scaleEffect(1.1)
                        .animation(
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isPresented
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.name)
                        .font(.merchantTitle)
                        .foregroundColor(.dialogueText)
                    
                    Text(achievement.description)
                        .font(.compassBody)
                        .foregroundColor(.mistGray)
                        .lineLimit(2)
                    
                    if let reward = achievement.rewardInfo {
                        Text("보상: \(reward.displayText)")
                            .font(.compassSmall)
                            .foregroundColor(.treasureGold)
                    }
                }
                
                Spacer()
            }
            
            // 닫기 버튼
            Button("확인") {
                withAnimation(.spring()) {
                    isPresented = false
                }
            }
            .buttonStyle(TreasureButtonStyle())
            .controlSize(.small)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient.parchmentGlow)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.treasureGold, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .scaleEffect(isPresented ? 1.0 : 0.8)
        .opacity(isPresented ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - AchievementSummary 컴포넌트 (프로필 등에서 사용)
struct AchievementSummary: View {
    let viewModel: AchievementViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("업적 현황")
                    .font(.merchantTitle)
                    .foregroundColor(.treasureGold)
                
                Spacer()
                
                Text("\(viewModel.completedCount) / \(viewModel.totalCount)")
                    .font(.merchantBody)
                    .foregroundColor(.dialogueText)
            }
            
            // 전체 진행률 바
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("전체 진행률")
                        .font(.compassBody)
                        .foregroundColor(.dialogueText)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.completionRate * 100))%")
                        .font(.compassBody)
                        .foregroundColor(.expGreen)
                }
                
                ProgressView(value: viewModel.completionRate)
                    .tint(.expGreen)
                    .scaleEffect(y: 2.0)
            }
            
            // 카테고리별 진행률
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(AchievementCategory.allCases, id: \.rawValue) { category in
                    let progress = viewModel.categoryProgress(for: category)
                    
                    HStack(spacing: 8) {
                        Image(systemName: category.icon)
                            .font(.system(size: 14))
                            .foregroundColor(category.color)
                        
                        Text(category.displayName)
                            .font(.compassSmall)
                            .foregroundColor(.dialogueText)
                        
                        Spacer()
                        
                        Text("\(progress.completed)/\(progress.total)")
                            .font(.compassSmall)
                            .foregroundColor(.mistGray)
                    }
                }
            }
        }
        .parchmentCard()
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AchievementMiniCard(
            achievement: Achievement.sampleAchievements[0],
            onTap: { print("Achievement tapped") }
        )
        
        AchievementMiniCard(
            achievement: Achievement.sampleAchievements[1],
            showProgress: false,
            onTap: { print("Achievement tapped") }
        )
    }
    .padding()
    .background(LinearGradient.oceanWave)
}