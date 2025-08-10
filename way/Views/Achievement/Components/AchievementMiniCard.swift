// 📁 Views/Achievement/Components/AchievementMiniCard.swift - 업적 미니 카드
import SwiftUI

struct AchievementMiniCard: View {
    let name: String
    let progress: Double
    let isCompleted: Bool
    let category: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 완료 아이콘
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(isCompleted ? .expGreen : .mistGray)
            
            // 업적 정보
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.merchantBody)
                        .foregroundColor(.dialogueText)
                    
                    Spacer()
                    
                    Text(category)
                        .font(.compassSmall)
                        .foregroundColor(.treasureGold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.treasureGold.opacity(0.2))
                        )
                }
                
                // 진행률 바 (완료되지 않은 경우만)
                if !isCompleted {
                    ProgressBar(
                        current: progress,
                        maximum: 1.0,
                        color: .manaBlue,
                        height: 6,
                        cornerRadius: 3
                    )
                }
            }
            
            // 진행률 텍스트
            if !isCompleted {
                Text("\(Int(progress * 100))%")
                    .font(.treasureCaption)
                    .foregroundColor(.manaBlue)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 12) {
        AchievementMiniCard(
            name: "첫 거래",
            progress: 1.0,
            isCompleted: true,
            category: "거래"
        )
        
        AchievementMiniCard(
            name: "수집가",
            progress: 0.7,
            isCompleted: false,
            category: "수집"
        )
        
        AchievementMiniCard(
            name: "탐험가",
            progress: 0.3,
            isCompleted: false,
            category: "탐험"
        )
    }
    .padding()
    .parchmentCard()
    .background(LinearGradient.oceanWave)
}