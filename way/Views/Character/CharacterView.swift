// 📁 Views/Character/CharacterView.swift - 캐릭터 시스템 메인 화면
import SwiftUI

struct CharacterView: View {
    @ObservedObject var gameManager: GameManager
    @State private var selectedTab: CharacterTab = .stats
    @State private var showStatAllocation = false
    @State private var showSkillTree = false
    
    enum CharacterTab: String, CaseIterable {
        case stats = "능력치"
        case skills = "기술"
        case achievements = "업적"
        case appearance = "외형"
        
        var icon: String {
            switch self {
            case .stats: return "chart.bar.fill"
            case .skills: return "brain.head.profile"
            case .achievements: return "star.fill"
            case .appearance: return "person.crop.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 수묵화 배경
                LinearGradient.paperBackground
                    .ignoresSafeArea()
                
                // 배경 산 실루엣
                VStack {
                    Spacer()
                    MountainSilhouette()
                        .frame(height: 120)
                        .opacity(0.1)
                }
                
                // 은은한 먹 점 패턴
                InkDotPattern()
                    .opacity(0.08)
                
                ScrollView {
                    LazyVStack(spacing: 25) {
                        // 수묵화 스타일 캐릭터 헤더
                        inkCharacterHeader
                        
                        // 수묵화 스타일 레벨 진행률
                        inkLevelProgressCard
                        
                        // 수묵화 스타일 탭 선택기
                        inkTabSelector
                        
                        // 탭별 콘텐츠
                        inkTabContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("여행자 정보")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("스탯 할당", systemImage: "plus.circle") {
                            showStatAllocation = true
                        }
                        .disabled(gameManager.player.statPoints == 0)
                        
                        Button("스킬 트리", systemImage: "brain") {
                            showSkillTree = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.brushText)
                    }
                }
            }
        }
        .sheet(isPresented: $showStatAllocation) {
            StatAllocationView(player: $gameManager.player)
        }
        .sheet(isPresented: $showSkillTree) {
            SkillTreeView(player: $gameManager.player)
        }
    }
    
    // MARK: - 수묵화 스타일 캐릭터 헤더
    private var inkCharacterHeader: some View {
        HStack(spacing: 20) {
            // 캐릭터 아바타 - 수묵화 스타일
            ZStack {
                Circle()
                    .fill(Color.softWhite)
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(Color.inkBlack.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: Color.inkMist.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: "figure.walk")
                    .font(.system(size: 40))
                    .foregroundColor(.brushText.opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // 캐릭터 이름과 레벨
                VStack(alignment: .leading, spacing: 4) {
                    Text(gameManager.player.name)
                        .font(.brushStroke)
                        .fontWeight(.semibold)
                        .foregroundColor(.brushText)
                    
                    Text("레벨 \(gameManager.player.level)")
                        .font(.inkText)
                        .foregroundColor(.fadeText)
                }
                
                // 여행자 등급 정보
                HStack(spacing: 10) {
                    Image(systemName: "seal.fill")
                        .foregroundColor(.brushText.opacity(0.6))
                        .font(.caption)
                    Text("\(gameManager.player.currentLicense.displayName)")
                        .font(.inkText)
                        .foregroundColor(.brushText.opacity(0.8))
                }
                
                // 사용 가능한 포인트들
                if gameManager.player.statPoints > 0 || gameManager.player.skillPoints > 0 {
                    HStack(spacing: 12) {
                        if gameManager.player.statPoints > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.brushText.opacity(0.6))
                                    .frame(width: 6, height: 6)
                                Text("능력 \(gameManager.player.statPoints)")
                                    .font(.whisperText)
                                    .foregroundColor(.brushText.opacity(0.8))
                            }
                        }
                        
                        if gameManager.player.skillPoints > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.brushText.opacity(0.6))
                                    .frame(width: 6, height: 6)
                                Text("기술 \(gameManager.player.skillPoints)")
                                    .font(.whisperText)
                                    .foregroundColor(.brushText.opacity(0.8))
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .inkCard()
    }
    
    // MARK: - 수묵화 스타일 레벨 진행률 카드
    private var inkLevelProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 레벨 정보
            HStack {
                Text("레벨 \(gameManager.player.level)")
                    .font(.brushStroke)
                    .foregroundColor(.brushText)
                
                Spacer()
                
                Text("\(gameManager.player.experience) / \(expRequiredForNextLevel) 경험치")
                    .font(.whisperText)
                    .foregroundColor(.fadeText)
            }
            
            // 경험치 바 - 수묵화 스타일
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.inkMist.opacity(0.3))
                        .frame(height: 8)
                    
                    // 진행률
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.brushText.opacity(0.6), Color.brushText],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * min(Double(gameManager.player.experience) / Double(expRequiredForNextLevel), 1.0),
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.5), value: gameManager.player.experience)
                }
            }
            .frame(height: 8)
            
            // 재화 정보
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.brushText.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text("\(gameManager.player.money) 전")
                        .font(.whisperText)
                        .foregroundColor(.brushText.opacity(0.8))
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.brushText.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text("신뢰도 \(gameManager.player.trustPoints)")
                        .font(.whisperText)
                        .foregroundColor(.brushText.opacity(0.8))
                }
            }
        }
        .inkCard()
    }
    
    // MARK: - 수묵화 스타일 탭 선택기
    private var inkTabSelector: some View {
        HStack(spacing: 0) {
            ForEach(CharacterTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: selectedTab == tab ? .medium : .regular))
                            .foregroundColor(selectedTab == tab ? .brushText : .fadeText)
                        
                        Text(tab.rawValue)
                            .font(.whisperText)
                            .fontWeight(selectedTab == tab ? .medium : .regular)
                            .foregroundColor(selectedTab == tab ? .brushText : .fadeText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.inkMist.opacity(0.2) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedTab == tab ? Color.inkBlack.opacity(0.1) : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
        }
        .inkCard()
    }
    
    // MARK: - 수묵화 스타일 탭별 콘텐츠
    @ViewBuilder
    private var inkTabContent: some View {
        switch selectedTab {
        case .stats:
            inkCharacterStatsView
        case .skills:
            inkCharacterSkillsView
        case .achievements:
            inkAchievementsView
        case .appearance:
            inkAppearanceView
        }
    }
    
    // MARK: - 수묵화 스타일 능력치 뷰
    private var inkCharacterStatsView: some View {
        VStack(spacing: 20) {
            // 기본 능력치
            VStack(alignment: .leading, spacing: 16) {
                Text("기본 덕목")
                    .font(.brushStroke)
                    .foregroundColor(.brushText)
                
                VStack(spacing: 12) {
                    InkStatRow(title: "무력", value: gameManager.player.strength, icon: "flame.fill")
                    InkStatRow(title: "지혜", value: gameManager.player.intelligence, icon: "brain.head.profile")
                    InkStatRow(title: "인덕", value: gameManager.player.charisma, icon: "heart.fill")
                    InkStatRow(title: "운세", value: gameManager.player.luck, icon: "star.fill")
                }
            }
            
            // 거래 기예
            VStack(alignment: .leading, spacing: 16) {
                Text("거래 기예")
                    .font(.brushStroke)
                    .foregroundColor(.brushText)
                
                VStack(spacing: 12) {
                    InkStatRow(title: "상술", value: gameManager.player.tradingSkill, icon: "cart.fill")
                    InkStatRow(title: "언변", value: gameManager.player.negotiationSkill, icon: "person.2.fill")
                    InkStatRow(title: "감별", value: gameManager.player.appraisalSkill, icon: "eye.fill")
                }
            }
        }
        .inkCard()
    }
    
    // MARK: - 수묵화 스타일 스킬 뷰
    private var inkCharacterSkillsView: some View {
        VStack(spacing: 20) {
            Text("무예 수련")
                .font(.brushStroke)
                .foregroundColor(.brushText)
            
            Text("곧 다양한 기예를 익힐 수 있습니다")
                .font(.inkText)
                .foregroundColor(.fadeText)
                .multilineTextAlignment(.center)
            
            Button("수련서 보기") {
                showSkillTree = true
            }
            .buttonStyle(InkButtonStyle())
        }
        .inkCard()
    }
    
    // MARK: - 수묵화 스타일 업적 뷰
    private var inkAchievementsView: some View {
        VStack(spacing: 20) {
            // 최근 업적들
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("최근 성취")
                        .font(.brushStroke)
                        .foregroundColor(.brushText)
                    
                    Spacer()
                    
                    NavigationLink("전체 보기") {
                        AchievementView(achievementManager: AchievementManager())
                    }
                    .font(.whisperText)
                    .foregroundColor(.fadeText)
                }
                
                // 샘플 업적들 - 수묵화 스타일
                VStack(spacing: 12) {
                    InkAchievementMiniCard(
                        title: "첫 거래",
                        description: "첫 번째 거래 완료",
                        isCompleted: true,
                        progress: 1,
                        total: 1
                    )
                    
                    InkAchievementMiniCard(
                        title: "수집가",
                        description: "다양한 물품 수집",
                        isCompleted: false,
                        progress: 7,
                        total: 10
                    )
                    
                    InkAchievementMiniCard(
                        title: "탐험가",
                        description: "여러 지역 탐방",
                        isCompleted: true,
                        progress: 5,
                        total: 5
                    )
                }
            }
        }
        .inkCard()
    }
    
    // MARK: - 수묵화 스타일 외형 뷰
    private var inkAppearanceView: some View {
        VStack(spacing: 20) {
            Text("의상 선택")
                .font(.brushStroke)
                .foregroundColor(.brushText)
            
            Text("곧 다양한 의상을 선택할 수 있습니다")
                .font(.inkText)
                .foregroundColor(.fadeText)
                .multilineTextAlignment(.center)
            
            // 미리보기 영역
            ZStack {
                Circle()
                    .fill(Color.softWhite)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.inkBlack.opacity(0.2), lineWidth: 2)
                    )
                
                Image(systemName: "figure.walk")
                    .font(.system(size: 60))
                    .foregroundColor(.brushText.opacity(0.7))
            }
            .shadow(color: Color.inkMist.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .inkCard()
    }
    
    // MARK: - 계산된 속성들
    private var expRequiredForNextLevel: Int {
        // TODO: 실제 경험치 공식 구현
        return gameManager.player.level * 100
    }
}

// MARK: - 수묵화 스타일 능력치 행 컴포넌트
struct InkStatRow: View {
    let title: String
    let value: Int
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(Color.inkMist.opacity(0.3))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.brushText.opacity(0.7))
            }
            
            // 제목과 값
            HStack {
                Text(title)
                    .font(.inkText)
                    .foregroundColor(.brushText)
                
                Spacer()
                
                Text("\(value)")
                    .font(.brushStroke)
                    .fontWeight(.medium)
                    .foregroundColor(.brushText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.softWhite.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.inkBlack.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - 수묵화 스타일 미니 업적 카드
struct InkAchievementMiniCard: View {
    let title: String
    let description: String
    let isCompleted: Bool
    let progress: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // 완료 상태 표시
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.brushText.opacity(0.2) : Color.inkMist.opacity(0.3))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isCompleted ? "checkmark.seal.fill" : "hourglass")
                    .font(.system(size: 16))
                    .foregroundColor(isCompleted ? .brushText : .fadeText)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // 제목
                Text(title)
                    .font(.inkText)
                    .fontWeight(.medium)
                    .foregroundColor(.brushText)
                
                // 설명
                Text(description)
                    .font(.whisperText)
                    .foregroundColor(.fadeText)
                
                // 진행률
                if !isCompleted {
                    HStack(spacing: 8) {
                        Text("(\(progress)/\(total))")
                            .font(.whisperText)
                            .foregroundColor(.fadeText)
                        
                        // 진행률 바
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.inkMist.opacity(0.3))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.brushText.opacity(0.6))
                                    .frame(
                                        width: geometry.size.width * (Double(progress) / Double(total)),
                                        height: 4
                                    )
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.softWhite.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.inkBlack.opacity(0.1), lineWidth: 1)
                )
        )
    }
}


// MARK: - Preview
#Preview {
    CharacterView(gameManager: GameManager())
}
