// 📁 Views/Merchant/Components/MoodIndicator.swift - 상인 기분 표시 컴포넌트
import SwiftUI

struct MoodIndicator: View {
    let mood: MerchantMood
    
    var body: some View {
        HStack(spacing: 6) {
            // 기분 아이콘
            Image(systemName: mood.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(moodColor)
            
            // 기분 텍스트
            Text(mood.moodDisplayName)
                .font(.compassSmall)
                .foregroundColor(moodColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(moodColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(moodColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    
    private var moodColor: Color {
        switch mood {
        case .happy, .excited, .friendly:
            return .expGreen
        case .neutral, .wise:
            return .mistGray
        case .grumpy, .sad:
            return .stormGray
        case .angry:
            return .compass
        case .mysterious:
            return .seaBlue
        case .greedy:
            return .treasureGold
        }
    }
}


#Preview {
    VStack(spacing: 16) {
        MoodIndicator(mood: .happy)
        MoodIndicator(mood: .grumpy)
        MoodIndicator(mood: .mysterious)
        MoodIndicator(mood: .wise)
        MoodIndicator(mood: .greedy)
    }
    .padding()
    .background(Color.parchment)
}
