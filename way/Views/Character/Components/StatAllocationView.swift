// 📁 Views/Character/Components/StatAllocationView.swift - 스탯 포인트 할당 뷰
import SwiftUI

struct StatAllocationView: View {
    @Binding var player: Player
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempStats: TempStats
    @State private var remainingPoints: Int
    
    init(player: Binding<Player>) {
        self._player = player
        self._tempStats = State(initialValue: TempStats(
            strength: player.wrappedValue.strength,
            intelligence: player.wrappedValue.intelligence,
            charisma: player.wrappedValue.charisma,
            luck: player.wrappedValue.luck
        ))
        self._remainingPoints = State(initialValue: player.wrappedValue.statPoints)
    }
    
    struct TempStats {
        var strength: Int
        var intelligence: Int
        var charisma: Int
        var luck: Int
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient.oceanWave
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 제목과 남은 포인트
                        header
                        
                        // 스탯 할당 섹션
                        statsAllocationSection
                        
                        // 미리보기 섹션
                        previewSection
                        
                        // 액션 버튼들
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("스탯 할당")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(.compass)
                }
            }
        }
    }
    
    // MARK: - 헤더
    private var header: some View {
        VStack(spacing: 12) {
            Text("능력치 포인트 할당")
                .font(.navigatorTitle)
                .foregroundColor(.treasureGold)
            
            HStack {
                Text("사용 가능한 포인트:")
                    .font(.merchantBody)
                    .foregroundColor(.dialogueText)
                
                Text("\(remainingPoints)")
                    .font(.pirateTitle)
                    .foregroundColor(.expGreen)
            }
            
            if remainingPoints == 0 {
                Text("모든 포인트가 할당되었습니다")
                    .font(.compassSmall)
                    .foregroundColor(.mistGray)
            }
        }
        .parchmentCard()
    }
    
    // MARK: - 스탯 할당 섹션
    private var statsAllocationSection: some View {
        VStack(spacing: 16) {
            Text("능력치")
                .font(.merchantBody)
                .foregroundColor(.treasureGold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                StatAllocationRow(
                    name: "힘",
                    description: "무거운 아이템을 더 많이 운반할 수 있습니다",
                    icon: "flame.fill",
                    color: .healthRed,
                    current: player.strength,
                    temp: $tempStats.strength,
                    remainingPoints: $remainingPoints
                )
                
                StatAllocationRow(
                    name: "지능",
                    description: "아이템 감정과 시장 분석 능력이 향상됩니다",
                    icon: "brain.head.profile",
                    color: .manaBlue,
                    current: player.intelligence,
                    temp: $tempStats.intelligence,
                    remainingPoints: $remainingPoints
                )
                
                StatAllocationRow(
                    name: "매력",
                    description: "거래 가격 협상과 상인 친밀도가 개선됩니다",
                    icon: "heart.fill",
                    color: .expGreen,
                    current: player.charisma,
                    temp: $tempStats.charisma,
                    remainingPoints: $remainingPoints
                )
                
                StatAllocationRow(
                    name: "행운",
                    description: "희귀 아이템 발견과 크리티컬 확률이 증가합니다",
                    icon: "star.fill",
                    color: .goldYellow,
                    current: player.luck,
                    temp: $tempStats.luck,
                    remainingPoints: $remainingPoints
                )
            }
        }
        .parchmentCard()
    }
    
    // MARK: - 미리보기 섹션
    private var previewSection: some View {
        VStack(spacing: 12) {
            Text("변경 미리보기")
                .font(.merchantBody)
                .foregroundColor(.treasureGold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                StatComparisonRow(name: "힘", current: player.strength, new: tempStats.strength)
                StatComparisonRow(name: "지능", current: player.intelligence, new: tempStats.intelligence)
                StatComparisonRow(name: "매력", current: player.charisma, new: tempStats.charisma)
                StatComparisonRow(name: "행운", current: player.luck, new: tempStats.luck)
            }
        }
        .parchmentCard()
    }
    
    // MARK: - 액션 버튼들
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 적용 버튼
            Button("변경사항 적용") {
                applyChanges()
            }
            .buttonStyle(TreasureButtonStyle())
            .disabled(!hasChanges)
            
            // 초기화 버튼
            Button("초기화") {
                resetChanges()
            }
            .buttonStyle(SeaButtonStyle())
            .disabled(!hasChanges)
        }
    }
    
    // MARK: - 계산된 속성들
    private var hasChanges: Bool {
        tempStats.strength != player.strength ||
        tempStats.intelligence != player.intelligence ||
        tempStats.charisma != player.charisma ||
        tempStats.luck != player.luck
    }
    
    // MARK: - 메서드들
    private func applyChanges() {
        player.strength = tempStats.strength
        player.intelligence = tempStats.intelligence
        player.charisma = tempStats.charisma
        player.luck = tempStats.luck
        player.statPoints = remainingPoints
        
        // TODO: 서버에 변경사항 전송
        
        dismiss()
    }
    
    private func resetChanges() {
        tempStats = TempStats(
            strength: player.strength,
            intelligence: player.intelligence,
            charisma: player.charisma,
            luck: player.luck
        )
        remainingPoints = player.statPoints
    }
}

// MARK: - StatAllocationRow 컴포넌트
struct StatAllocationRow: View {
    let name: String
    let description: String
    let icon: String
    let color: Color
    let current: Int
    @Binding var temp: Int
    @Binding var remainingPoints: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // 스탯 아이콘과 이름
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 18))
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.merchantBody)
                            .foregroundColor(.dialogueText)
                        Text(description)
                            .font(.compassSmall)
                            .foregroundColor(.mistGray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // 스탯 조절 버튼들
                HStack(spacing: 16) {
                    // 현재 값
                    Text("\(current)")
                        .font(.statText)
                        .foregroundColor(.mistGray)
                        .frame(minWidth: 25)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(.mistGray)
                    
                    // 감소 버튼
                    Button(action: {
                        if temp > current {
                            temp -= 1
                            remainingPoints += 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(temp > current ? color : .stormGray)
                    }
                    .disabled(temp <= current)
                    
                    // 새로운 값
                    Text("\(temp)")
                        .font(.statText)
                        .foregroundColor(temp > current ? color : .dialogueText)
                        .frame(minWidth: 25)
                    
                    // 증가 버튼
                    Button(action: {
                        if remainingPoints > 0 {
                            temp += 1
                            remainingPoints -= 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(remainingPoints > 0 ? color : .stormGray)
                    }
                    .disabled(remainingPoints <= 0)
                }
            }
            
            // 증가량 표시
            if temp > current {
                HStack {
                    Spacer()
                    Text("+\(temp - current)")
                        .font(.compassSmall)
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color.opacity(0.2))
                        )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - StatComparisonRow 컴포넌트
struct StatComparisonRow: View {
    let name: String
    let current: Int
    let new: Int
    
    var body: some View {
        HStack {
            Text(name)
                .font(.merchantBody)
                .foregroundColor(.dialogueText)
            
            Spacer()
            
            Text("\(current)")
                .font(.statText)
                .foregroundColor(.mistGray)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundColor(.mistGray)
            
            Text("\(new)")
                .font(.statText)
                .foregroundColor(new > current ? .expGreen : .dialogueText)
            
            if new > current {
                Text("(+\(new - current))")
                    .font(.compassSmall)
                    .foregroundColor(.expGreen)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    StatAllocationView(player: .constant(Player()))
}