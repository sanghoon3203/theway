// 📁 Views/Character/Components/LevelProgressCard.swift - 레벨 진행률 표시 카드
import SwiftUI

struct LevelProgressCard: View {
    let currentLevel: Int
    let currentExp: Int
    let nextLevelExp: Int
    let money: Int
    let trustPoints: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // 레벨과 경험치 바
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("레벨 \(currentLevel)")
                        .font(.navigatorTitle)
                        .foregroundColor(.treasureGold)
                    
                    Spacer()
                    
                    Text("\(currentExp) / \(nextLevelExp) EXP")
                        .font(.treasureCaption)
                        .foregroundColor(.expGreen)
                }
                
                // 경험치 바
                VStack {
                    Text("경험치")
                        .font(.compassSmall)
                        .foregroundColor(.dialogueText)
                }
                .statBar(
                    current: Double(currentExp),
                    maximum: Double(nextLevelExp),
                    color: .expGreen
                )
            }
            
            Divider()
                .background(Color.dialogueBorder)
            
            // 재화 정보
            HStack(spacing: 20) {
                // 골드
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: NavigationIcons.coin)
                            .foregroundColor(.goldYellow)
                            .font(.system(size: 16))
                        Text("골드")
                            .font(.merchantBody)
                            .foregroundColor(.dialogueText)
                    }
                    
                    Text("\(money.formatted())원")
                        .font(.statText)
                        .foregroundColor(.goldYellow)
                }
                
                Spacer()
                
                // 신뢰 포인트
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.compass)
                            .font(.system(size: 16))
                        Text("신뢰도")
                            .font(.merchantBody)
                            .foregroundColor(.dialogueText)
                    }
                    
                    Text("\(trustPoints)")
                        .font(.statText)
                        .foregroundColor(.compass)
                }
            }
            
            // 다음 레벨까지의 혜택 미리보기
            if expToNextLevel > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("다음 레벨 혜택")
                        .font(.merchantBody)
                        .foregroundColor(.treasureGold)
                    
                    HStack(spacing: 16) {
                        Label("+2 스탯", systemImage: "plus.circle")
                            .font(.compassSmall)
                            .foregroundColor(.expGreen)
                        
                        Label("+1 스킬", systemImage: "brain")
                            .font(.compassSmall)
                            .foregroundColor(.manaBlue)
                        
                        Spacer()
                        
                        Text("\(expToNextLevel) EXP 필요")
                            .font(.compassSmall)
                            .foregroundColor(.mistGray)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.menuBackground.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.treasureGold.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // 레벨 업 가능 상태
                VStack(spacing: 8) {
                    Text("🎉 레벨 업 가능!")
                        .font(.merchantBody)
                        .foregroundColor(.treasureGold)
                    
                    Button("레벨 업!") {
                        // TODO: 레벨 업 로직 구현
                    }
                    .buttonStyle(TreasureButtonStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient.treasureShine.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.treasureGold, lineWidth: 2)
                        )
                )
            }
        }
        .parchmentCard()
    }
    
    // MARK: - 계산된 속성들
    private var expToNextLevel: Int {
        max(0, nextLevelExp - currentExp)
    }
    
    private var levelProgress: Double {
        guard nextLevelExp > 0 else { return 1.0 }
        return Double(currentExp) / Double(nextLevelExp)
    }
}

// MARK: - ProgressRing 컴포넌트 (원형 진행률 바)
struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    init(progress: Double, color: Color = .expGreen, lineWidth: CGFloat = 8) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // 배경 링
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            // 진행률 링
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.7), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            // 중앙 텍스트
            Text("\(Int(progress * 100))%")
                .font(.statText)
                .foregroundColor(color)
        }
    }
}

// MARK: - 소형 스탯 카드
struct MiniStatCard: View {
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
                Text(title)
                    .font(.compassSmall)
                    .foregroundColor(.mistGray)
                
                Text(value)
                    .font(.treasureCaption)
                    .foregroundColor(color)
            }
        }
        .padding()
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

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            LevelProgressCard(
                currentLevel: 5,
                currentExp: 350,
                nextLevelExp: 500,
                money: 125000,
                trustPoints: 85
            )
            
            LevelProgressCard(
                currentLevel: 10,
                currentExp: 1000,
                nextLevelExp: 1000,
                money: 500000,
                trustPoints: 250
            )
            
            HStack(spacing: 12) {
                MiniStatCard(title: "힘", value: "15", icon: "flame.fill", color: .healthRed)
                MiniStatCard(title: "지능", value: "12", icon: "brain", color: .manaBlue)
                MiniStatCard(title: "매력", value: "18", icon: "heart.fill", color: .expGreen)
            }
            
            ProgressRing(progress: 0.75, color: .expGreen)
                .frame(width: 100, height: 100)
        }
        .padding()
    }
    .background(LinearGradient.oceanWave)
}