// 📁 Views/Merchant/Components/MoodIndicator.swift - 상인 기분 표시 컴포넌트
import SwiftUI

struct MoodIndicator: View {
    let mood: MerchantMood
    
    var body: some View {
        HStack(spacing: 6) {
            // 기분 아이콘
            Image(systemName: moodIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(moodColor)
            
            // 기분 텍스트
            Text(mood.displayName)
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
    
    private var moodIcon: String {
        switch mood {
        case .happy:
            return "face.smiling"
        case .neutral:
            return "face.dashed"
        case .grumpy:
            return "face.frowning"
        case .excited:
            return "sparkles"
        case .sad:
            return "cloud.rain"
        case .angry:
            return "flame"
        case .mysterious:
            return "questionmark.circle"
        case .wise:
            return "brain.head.profile"
        case .greedy:
            return "dollarsign.circle"
        case .friendly:
            return "heart.circle"
        }
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

// MerchantMood enum 확장
extension MerchantMood {
    var displayName: String {
        switch self {
        case .happy: return "기분 좋음"
        case .neutral: return "평범함"
        case .grumpy: return "기분 나쁨"
        case .excited: return "신남"
        case .sad: return "우울함"
        case .angry: return "화남"
        case .mysterious: return "신비로움"
        case .wise: return "현명함"
        case .greedy: return "욕심부림"
        case .friendly: return "친근함"
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