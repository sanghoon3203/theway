// 📁 Views/Merchant/Components/RelationshipMeter.swift - 상인 관계도 표시 컴포넌트
import SwiftUI

struct RelationshipMeter: View {
    let level: Int
    let showDetails: Bool
    
    init(level: Int, showDetails: Bool = true) {
        self.level = level
        self.showDetails = showDetails
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 관계 아이콘
            Image(systemName: relationshipIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(relationshipColor)
            
            if showDetails {
                VStack(alignment: .leading, spacing: 2) {
                    // 관계 레벨 텍스트
                    Text(relationshipTitle)
                        .font(.compassSmall)
                        .foregroundColor(.dialogueText)
                    
                    // 진행률 바
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(relationshipColor)
                                .frame(width: geometry.size.width * progressPercentage, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            } else {
                // 간단 표시 모드
                Text(relationshipTitle)
                    .font(.compassSmall)
                    .foregroundColor(relationshipColor)
            }
        }
        .padding(.horizontal, showDetails ? 12 : 8)
        .padding(.vertical, showDetails ? 8 : 4)
        .background(
            RoundedRectangle(cornerRadius: showDetails ? 12 : 8)
                .fill(relationshipColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: showDetails ? 12 : 8)
                        .stroke(relationshipColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Computed Properties
    
    private var relationshipStage: RelationshipStage {
        switch level {
        case 0..<10:
            return .stranger
        case 10..<25:
            return .acquaintance
        case 25..<50:
            return .friend
        case 50..<75:
            return .goodFriend
        case 75..<90:
            return .closeFriend
        case 90...100:
            return .trustedPartner
        default:
            return .stranger
        }
    }
    
    private var relationshipTitle: String {
        relationshipStage.displayName
    }
    
    private var relationshipIcon: String {
        relationshipStage.icon
    }
    
    private var relationshipColor: Color {
        relationshipStage.color
    }
    
    private var progressPercentage: Double {
        let stageRange = relationshipStage.range
        let stageProgress = level - stageRange.lowerBound
        let stageSize = stageRange.upperBound - stageRange.lowerBound + 1
        return Double(stageProgress) / Double(stageSize)
    }
    
    // MARK: - RelationshipStage Enum
    
    private enum RelationshipStage {
        case stranger
        case acquaintance
        case friend
        case goodFriend
        case closeFriend
        case trustedPartner
        
        var displayName: String {
            switch self {
            case .stranger: return "낯선 사람"
            case .acquaintance: return "아는 사이"
            case .friend: return "친구"
            case .goodFriend: return "좋은 친구"
            case .closeFriend: return "절친"
            case .trustedPartner: return "신뢰하는 동반자"
            }
        }
        
        var icon: String {
            switch self {
            case .stranger: return "person"
            case .acquaintance: return "person.wave.2"
            case .friend: return "person.2"
            case .goodFriend: return "heart"
            case .closeFriend: return "heart.fill"
            case .trustedPartner: return "crown.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .stranger: return .stormGray
            case .acquaintance: return .mistGray
            case .friend: return .oceanTeal
            case .goodFriend: return .expGreen
            case .closeFriend: return .treasureGold
            case .trustedPartner: return .compass
            }
        }
        
        var range: ClosedRange<Int> {
            switch self {
            case .stranger: return 0...9
            case .acquaintance: return 10...24
            case .friend: return 25...49
            case .goodFriend: return 50...74
            case .closeFriend: return 75...89
            case .trustedPartner: return 90...100
            }
        }
    }
}

// MARK: - RelationshipDetailView (상세 관계 정보)
struct RelationshipDetailView: View {
    let merchant: Merchant
    let totalTrades: Int
    let totalSpent: Int
    let lastInteraction: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 제목
            Text("관계 정보")
                .font(.navigatorTitle)
                .foregroundColor(.dialogueText)
            
            // 관계 미터 (상세 버전)
            RelationshipMeter(level: merchant.friendshipLevel, showDetails: true)
            
            // 거래 통계
            VStack(alignment: .leading, spacing: 8) {
                Text("거래 기록")
                    .font(.merchantBody)
                    .foregroundColor(.treasureGold)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("총 거래 횟수")
                            .font(.compassSmall)
                            .foregroundColor(.mistGray)
                        Text("\(totalTrades)회")
                            .font(.statText)
                            .foregroundColor(.dialogueText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("총 거래 금액")
                            .font(.compassSmall)
                            .foregroundColor(.mistGray)
                        Text("\(totalSpent.formatted())원")
                            .font(.statText)
                            .foregroundColor(.goldYellow)
                    }
                }
            }
            
            // 특별 혜택
            if merchant.friendshipLevel >= 50 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("특별 혜택")
                        .font(.merchantBody)
                        .foregroundColor(.treasureGold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 가격 할인 5~10%")
                        Text("• 특별 상품 접근 권한")
                        Text("• 우선 입고 정보 제공")
                        
                        if merchant.friendshipLevel >= 75 {
                            Text("• 독점 상품 거래 가능")
                                .foregroundColor(.treasureGold)
                        }
                    }
                    .font(.compassSmall)
                    .foregroundColor(.dialogueText)
                }
            }
            
            // 마지막 상호작용 시간
            if let lastInteraction = lastInteraction {
                Text("마지막 대화: \(lastInteraction, format: .relative(presentation: .named))")
                    .font(.compassSmall)
                    .foregroundColor(.mistGray)
            }
        }
        .padding(20)
        .dialogueBox()
    }
}

#Preview {
    VStack(spacing: 20) {
        RelationshipMeter(level: 15, showDetails: true)
        RelationshipMeter(level: 35, showDetails: true)
        RelationshipMeter(level: 60, showDetails: true)
        RelationshipMeter(level: 85, showDetails: true)
        
        HStack {
            RelationshipMeter(level: 25, showDetails: false)
            RelationshipMeter(level: 50, showDetails: false)
            RelationshipMeter(level: 90, showDetails: false)
        }
    }
    .padding()
    .background(LinearGradient.oceanWave)
}