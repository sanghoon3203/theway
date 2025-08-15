// 📁 Views/Achievement/Components/AchievementCard.swift - 업적 카드 컴포넌트
import SwiftUI

struct AchievementCard: View {
    let achievement: Achievement
    let onClaim: (Achievement) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                // 업적 아이콘
                achievementIcon
                
                // 업적 정보
                VStack(alignment: .leading, spacing: 8) {
                    // 업적 이름과 상태
                    HStack {
                        Text(achievement.name)
                            .font(.merchantBody)
                            .foregroundColor(.treasureGold)
                        
                        Spacer()
                        
                        achievementStatusBadge
                    }
                    
                    // 업적 설명
                    Text(achievement.description)
                        .font(.compassSmall)
                        .foregroundColor(.dialogueText)
                        .multilineTextAlignment(.leading)
                    
                    // 진행률 정보
                    progressSection
                    
                    // 보상 정보
                    rewardSection
                }
                
                Spacer()
            }
            
            // 클레임 버튼 (완료했지만 미수령인 경우에만)
            if achievement.isCompleted && !achievement.claimed {
                Button("보상 수령") {
                    onClaim(achievement)
                }
                .buttonStyle(TreasureButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardBorderColor, lineWidth: cardBorderWidth)
                )
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - 업적 아이콘
    private var achievementIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(iconBorderColor, lineWidth: 2)
                )
            
            Image(systemName: categoryIcon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(iconColor)
            
            // 완료 체크마크
            if achievement.isCompleted {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.expGreen)
                            .background(Color.white, in: Circle())
                    }
                }
                .frame(width: 60, height: 60)
            }
        }
    }
    
    // MARK: - 업적 상태 배지
    private var achievementStatusBadge: some View {
        Group {
            if achievement.isCompleted && !achievement.claimed {
                Text("수령 대기")
                    .font(.compassSmall)
                    .foregroundColor(.treasureGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.treasureGold.opacity(0.2))
                    )
            } else if achievement.isCompleted && achievement.claimed {
                Text("완료")
                    .font(.compassSmall)
                    .foregroundColor(.expGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.expGreen.opacity(0.2))
                    )
            } else if achievement.currentProgress > 0 {
                Text("진행 중")
                    .font(.compassSmall)
                    .foregroundColor(.manaBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.manaBlue.opacity(0.2))
                    )
            }
        }
    }
    
    // MARK: - 진행률 섹션
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("진행률")
                    .font(.compassSmall)
                    .foregroundColor(.mistGray)
                
                Spacer()
                
                Text("\(achievement.currentProgress) / \(achievement.conditionValue)")
                    .font(.treasureCaption)
                    .foregroundColor(progressColor)
            }
            
            // 진행률 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [progressColor.opacity(0.8), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * achievement.progressPercentage,
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.5), value: achievement.progressPercentage)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - 보상 섹션
    private var rewardSection: some View {
        HStack(spacing: 8) {
            Image(systemName: rewardIcon)
                .font(.system(size: 14))
                .foregroundColor(.treasureGold)
            
            Text("보상: \(rewardDescription)")
                .font(.compassSmall)
                .foregroundColor(.treasureGold)
            
            Spacer()
        }
    }
    
    // MARK: - 계산된 속성들
    private var categoryIcon: String {
        switch achievement.category {
        case .trading: return "cart.fill"
        case .exploration: return "map.fill"
        case .social: return "person.2.fill"
        case .collection: return "bag.fill"
        case .character: return "person.circle.fill"
        }
    }
    
    private var categoryColor: Color {
        switch achievement.category {
        case .trading: return .goldYellow
        case .exploration: return .seaBlue
        case .social: return .expGreen
        case .collection: return .manaBlue
        case .character: return .compass
        }
    }
    
    private var cardBackground: Color {
        if achievement.isCompleted && !achievement.claimed {
            return Color.treasureGold.opacity(0.1)
        } else if achievement.isCompleted {
            return Color.expGreen.opacity(0.1)
        } else {
            return Color.parchment.opacity(0.8)
        }
    }
    
    private var cardBorderColor: Color {
        if achievement.isCompleted && !achievement.claimed {
            return .treasureGold
        } else if achievement.isCompleted {
            return .expGreen
        } else {
            return Color.dialogueBorder.opacity(0.3)
        }
    }
    
    private var cardBorderWidth: CGFloat {
        achievement.isCompleted ? 2 : 1
    }
    
    private var iconBackgroundColor: Color {
        if achievement.isCompleted {
            return categoryColor.opacity(0.2)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var iconBorderColor: Color {
        achievement.isCompleted ? categoryColor : Color.gray.opacity(0.3)
    }
    
    private var iconColor: Color {
        achievement.isCompleted ? categoryColor : Color.gray
    }
    
    private var progressColor: Color {
        if achievement.isCompleted {
            return .expGreen
        } else if achievement.currentProgress > 0 {
            return categoryColor
        } else {
            return .mistGray
        }
    }
    
    private var rewardIcon: String {
        switch achievement.rewardType {
        case "exp": return "star.fill"
        case "money": return "dollarsign.circle.fill"
        case "cosmetic": return "crown.fill"
        case "title": return "flag.fill"
        case "item": return "gift.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private var rewardDescription: String {
        switch achievement.rewardType {
        case "exp": return "\(achievement.rewardValue) 경험치"
        case "money": return "\(achievement.rewardValue)원"
        case "cosmetic": return "코스메틱 아이템"
        case "title": return "칭호 '\(achievement.rewardValue)'"
        case "item": return "특별 아이템"
        default: return achievement.rewardValue
        }
    }
}


// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        AchievementCard(
            achievement: {
                var achievement = Achievement(
                    id: "test1",
                    name: "첫 거래",
                    description: "첫 번째 거래를 완료하세요",
                    category: .trading,
                    conditionType: "trade_count",
                    conditionValue: 1,
                    rewardType: "exp",
                    rewardValue: #"{"experience": 50}"#
                )
                achievement.currentProgress = 1
                achievement.isCompleted = true
                achievement.claimed = false
                return achievement
            }()
        ) { _ in }
        
        AchievementCard(
            achievement: {
                var achievement = Achievement(
                    id: "test2",
                    name: "수집가",
                    description: "10개의 서로 다른 아이템을 수집하세요",
                    category: .collection,
                    conditionType: "unique_items",
                    conditionValue: 10,
                    rewardType: "cosmetic",
                    rewardValue: #"{"cosmetic_id": 101}"#
                )
                achievement.currentProgress = 7
                return achievement
            }()
        ) { _ in }
    }
    .padding()
    .background(LinearGradient.oceanWave)
}
