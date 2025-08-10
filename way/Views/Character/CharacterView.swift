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
                // 배경
                LinearGradient.oceanWave
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // 캐릭터 헤더
                        characterHeader
                        
                        // 레벨 진행률 카드
                        levelProgressCard
                        
                        // 탭 선택기
                        tabSelector
                        
                        // 탭별 콘텐츠
                        tabContent
                    }
                    .padding()
                }
            }
            .navigationTitle("캐릭터")
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
                            .foregroundColor(.treasureGold)
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
    
    // MARK: - 캐릭터 헤더
    private var characterHeader: some View {
        HStack(spacing: 16) {
            // 캐릭터 아바타
            AsyncImage(url: URL(string: "https://via.placeholder.com/100")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.mistGray)
            }
            .characterPortrait(size: 100)
            
            VStack(alignment: .leading, spacing: 8) {
                // 캐릭터 이름과 레벨
                VStack(alignment: .leading, spacing: 2) {
                    Text(gameManager.player.name)
                        .font(.navigatorTitle)
                        .foregroundColor(.dialogueText)
                    
                    Text("레벨 \(gameManager.player.level)")
                        .font(.treasureCaption)
                        .foregroundColor(.treasureGold)
                }
                
                // 라이센스 정보
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.seaBlue)
                    Text("\(gameManager.player.currentLicense.displayName)")
                        .font(.merchantBody)
                        .foregroundColor(.seaBlue)
                }
                
                // 사용 가능한 포인트들
                HStack(spacing: 16) {
                    if gameManager.player.statPoints > 0 {
                        Label("\(gameManager.player.statPoints)", systemImage: "plus.circle.fill")
                            .font(.compassSmall)
                            .foregroundColor(.expGreen)
                    }
                    
                    if gameManager.player.skillPoints > 0 {
                        Label("\(gameManager.player.skillPoints)", systemImage: "brain.fill")
                            .font(.compassSmall)
                            .foregroundColor(.manaBlue)
                    }
                }
            }
            
            Spacer()
        }
        .parchmentCard()
    }
    
    // MARK: - 레벨 진행률 카드
    private var levelProgressCard: some View {
        LevelProgressCard(
            currentLevel: gameManager.player.level,
            currentExp: gameManager.player.experience,
            nextLevelExp: expRequiredForNextLevel,
            money: gameManager.player.money,
            trustPoints: gameManager.player.trustPoints
        )
    }
    
    // MARK: - 탭 선택기
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(CharacterTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        Text(tab.rawValue)
                            .font(.compassSmall)
                    }
                }
                .buttonStyle(JRPGMenuButtonStyle(isSelected: selectedTab == tab))
                .frame(maxWidth: .infinity)
            }
        }
        .parchmentCard()
    }
    
    // MARK: - 탭별 콘텐츠
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .stats:
            characterStatsView
        case .skills:
            characterSkillsView
        case .achievements:
            achievementsView
        case .appearance:
            appearanceView
        }
    }
    
    // MARK: - 능력치 뷰
    private var characterStatsView: some View {
        VStack(spacing: 16) {
            // 기본 능력치
            VStack(alignment: .leading, spacing: 12) {
                Text("기본 능력치")
                    .font(.merchantBody)
                    .foregroundColor(.treasureGold)
                
                VStack(spacing: 8) {
                    StatRow(name: "힘", current: gameManager.player.strength, icon: "flame.fill", color: .healthRed)
                    StatRow(name: "지능", current: gameManager.player.intelligence, icon: "brain.head.profile", color: .manaBlue)
                    StatRow(name: "매력", current: gameManager.player.charisma, icon: "heart.fill", color: .expGreen)
                    StatRow(name: "행운", current: gameManager.player.luck, icon: "star.fill", color: .goldYellow)
                }
            }
            
            // 거래 기술
            VStack(alignment: .leading, spacing: 12) {
                Text("거래 기술")
                    .font(.merchantBody)
                    .foregroundColor(.treasureGold)
                
                VStack(spacing: 8) {
                    StatRow(name: "거래 기술", current: gameManager.player.tradingSkill, icon: "cart.fill", color: .treasureGold)
                    StatRow(name: "협상 기술", current: gameManager.player.negotiationSkill, icon: "person.2.fill", color: .oceanTeal)
                    StatRow(name: "감정 기술", current: gameManager.player.appraisalSkill, icon: "eye.fill", color: .seaBlue)
                }
            }
        }
        .parchmentCard()
    }
    
    // MARK: - 스킬 뷰
    private var characterSkillsView: some View {
        VStack(spacing: 16) {
            Text("스킬 시스템 (준비 중)")
                .font(.merchantBody)
                .foregroundColor(.mistGray)
            
            Button("스킬 트리 보기") {
                showSkillTree = true
            }
            .buttonStyle(TreasureButtonStyle())
        }
        .parchmentCard()
    }
    
    // MARK: - 업적 뷰
    private var achievementsView: some View {
        VStack(spacing: 16) {
            // 최근 업적들 (상위 3개)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("최근 업적")
                        .font(.merchantBody)
                        .foregroundColor(.treasureGold)
                    
                    Spacer()
                    
                    NavigationLink("전체 보기") {
                        AchievementView(achievementManager: AchievementManager())
                    }
                    .font(.compassSmall)
                    .foregroundColor(.seaBlue)
                }
                
                // 샘플 업적들
                VStack(spacing: 8) {
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
                        progress: 1.0,
                        isCompleted: true,
                        category: "탐험"
                    )
                }
            }
        }
        .parchmentCard()
    }
    
    // MARK: - 외형 뷰
    private var appearanceView: some View {
        VStack(spacing: 16) {
            Text("캐릭터 커스터마이징 (준비 중)")
                .font(.merchantBody)
                .foregroundColor(.mistGray)
            
            // TODO: 외형 커스터마이징 구현
            Text("곧 캐릭터 외형을 변경할 수 있습니다!")
                .font(.compassSmall)
                .foregroundColor(.dialogueText)
        }
        .parchmentCard()
    }
    
    // MARK: - 계산된 속성들
    private var expRequiredForNextLevel: Int {
        // TODO: 실제 경험치 공식 구현
        return gameManager.player.level * 100
    }
}

// MARK: - StatRow 컴포넌트
struct StatRow: View {
    let name: String
    let current: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(name)
                .font(.merchantBody)
                .foregroundColor(.dialogueText)
            
            Spacer()
            
            Text("\(current)")
                .font(.statText)
                .foregroundColor(color)
                .frame(minWidth: 30, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    CharacterView(gameManager: GameManager())
}