// 📁 Views/Merchant/MerchantDialogueView.swift - 상인 대화 시스템
import SwiftUI
import CoreLocation

struct MerchantDialogueView: View {
    let merchant: Merchant
    @State private var currentDialogue: String = ""
    @State private var dialogueOptions: [DialogueOption] = []
    @State private var showRelationshipInfo = false
    @State private var showSpecialServices = false
    @Environment(\.dismiss) private var dismiss
    
    // 대화 옵션 모델
    struct DialogueOption: Identifiable {
        let id = UUID()
        let text: String
        let type: DialogueType
        let requiresRelationship: Int?
        let action: () -> Void
        
        enum DialogueType {
            case greeting
            case trade
            case friendship
            case quest
            case goodbye
            case specialService
        }
    }
    
    var body: some View {
        ZStack {
            // 배경
            LinearGradient.oceanWave
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 상인 정보
                merchantHeader
                
                Spacer()
                
                // 대화창 영역
                dialogueArea
                
                // 대화 옵션들
                dialogueOptionsView
                
                // 하단 액션 버튼들
                actionButtons
            }
            .padding()
        }
        .onAppear {
            setupInitialDialogue()
        }
    }
    
    // MARK: - 상인 헤더 정보
    private var merchantHeader: some View {
        HStack {
            // 상인 포트레이트
            AsyncImage(url: URL(string: "https://via.placeholder.com/80")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.mistGray)
            }
            .characterPortrait(size: 80)
            
            VStack(alignment: .leading, spacing: 8) {
                // 상인 이름과 직함
                VStack(alignment: .leading, spacing: 2) {
                    Text(merchant.name)
                        .font(.navigatorTitle)
                        .foregroundColor(.dialogueText)
                    
                    if let title = merchant.title {
                        Text(title)
                            .font(.treasureCaption)
                            .foregroundColor(.treasureGold)
                    }
                }
                
                // 상인 기분 표시
                HStack(spacing: 8) {
                    MoodIndicator(mood: merchant.mood)
                    
                    Button(action: { showRelationshipInfo.toggle() }) {
                        RelationshipMeter(
                            level: merchant.friendshipLevel,
                            showDetails: false
                        )
                    }
                }
                
                // 상인 타입과 라이센스 요구사항
                HStack(spacing: 12) {
                    Text(merchant.type.displayName)
                        .font(.compassSmall)
                        .foregroundColor(.oceanTeal)
                    
                    Text("라이센스 Lv.\(merchant.requiredLicense.rawValue)")
                        .font(.compassSmall)
                        .foregroundColor(.shipBrown)
                }
            }
            
            Spacer()
            
            // 닫기 버튼
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.stormGray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient.parchmentGlow)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.dialogueBorder, lineWidth: 2)
                )
        )
    }
    
    // MARK: - 대화창 영역
    private var dialogueArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentDialogue)
                .font(.dialogueText)
                .lineSpacing(4)
                .animation(.easeInOut(duration: 0.3), value: currentDialogue)
        }
        .dialogueBox(characterName: merchant.name)
        .padding(.vertical)
    }
    
    // MARK: - 대화 옵션들
    private var dialogueOptionsView: some View {
        LazyVStack(spacing: 8) {
            ForEach(dialogueOptions) { option in
                DialogueOptionButton(
                    text: option.text,
                    isEnabled: canSelectOption(option),
                    action: option.action
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - 액션 버튼들
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // 거래 시작 버튼
            Button("거래하기") {
                // TODO: 거래 화면으로 이동
            }
            .buttonStyle(TreasureButtonStyle())
            
            // 특별 서비스 버튼
            if !merchant.specialAbilities.isEmpty {
                Button("특별 서비스") {
                    showSpecialServices.toggle()
                }
                .buttonStyle(SeaButtonStyle())
            }
            
            Spacer()
            
            // 관계 정보 버튼
            Button(action: { showRelationshipInfo.toggle() }) {
                Image(systemName: "heart.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.compass)
            }
        }
        .padding()
    }
    
    // MARK: - 메서드들
    private func setupInitialDialogue() {
        // 현재 관계와 상황에 맞는 초기 대화 설정
        currentDialogue = getGreetingDialogue()
        dialogueOptions = generateDialogueOptions()
    }
    
    private func getGreetingDialogue() -> String {
        // 상인 성격과 관계에 따른 인사말
        switch merchant.personality {
        case .friendly:
            return merchant.friendshipLevel > 50 ? 
                "안녕하세요, 오래된 친구! 오늘은 뭘 도와드릴까요?" :
                "어서 오세요! 좋은 물건들이 많이 들어왔답니다."
            
        case .mysterious:
            return "...운명이 당신을 이곳으로 이끌었군요. 무엇을 찾고 계신가요?"
            
        case .greedy:
            return "호호, 돈 냄새가 나는 손님이 오셨군요. 뭘 사실 건가요?"
            
        case .wise:
            return "젊은이, 이 늙은 상인에게 무엇을 구하러 왔나요?"
            
        case .cheerful:
            return "하하! 반갑습니다! 오늘도 좋은 하루네요!"
            
        case .serious:
            return "어서 오십시오. 무엇을 찾고 계신지요?"
            
        case .eccentric:
            return "오호! 흥미로운 손님이 오셨군요. 특별한 것을 찾나요?"
        }
    }
    
    private func generateDialogueOptions() -> [DialogueOption] {
        var options: [DialogueOption] = []
        
        // 기본 대화 옵션들
        options.append(DialogueOption(
            text: "안녕하세요, 잘 지내시나요?",
            type: .greeting,
            requiresRelationship: nil
        ) {
            handleGreeting()
        })
        
        options.append(DialogueOption(
            text: "물건을 보여주세요.",
            type: .trade,
            requiresRelationship: nil
        ) {
            handleTrade()
        })
        
        // 친밀도 기반 옵션들
        if merchant.friendshipLevel > 25 {
            options.append(DialogueOption(
                text: "요즘 어떻게 지내세요?",
                type: .friendship,
                requiresRelationship: 25
            ) {
                handleFriendshipTalk()
            })
        }
        
        // 퀘스트 옵션
        if merchant.isQuestGiver && merchant.friendshipLevel > 10 {
            options.append(DialogueOption(
                text: "혹시 도움이 필요한 일이 있나요?",
                type: .quest,
                requiresRelationship: 10
            ) {
                handleQuestInquiry()
            })
        }
        
        // 특별 서비스 옵션
        if !merchant.specialAbilities.isEmpty && merchant.friendshipLevel > 50 {
            options.append(DialogueOption(
                text: "특별한 서비스에 대해 알려주세요.",
                type: .specialService,
                requiresRelationship: 50
            ) {
                handleSpecialService()
            })
        }
        
        // 작별 인사
        options.append(DialogueOption(
            text: "그럼 이만 가보겠습니다.",
            type: .goodbye,
            requiresRelationship: nil
        ) {
            handleGoodbye()
        })
        
        return options
    }
    
    private func canSelectOption(_ option: DialogueOption) -> Bool {
        guard let requiredRelationship = option.requiresRelationship else { return true }
        return merchant.friendshipLevel >= requiredRelationship
    }
    
    // MARK: - 대화 액션 핸들러들
    private func handleGreeting() {
        switch merchant.personality {
        case .friendly:
            currentDialogue = "네, 덕분에 잘 지내고 있어요! 당신도 건강해 보이시네요."
        case .mysterious:
            currentDialogue = "...시간은 모든 것을 변화시키죠. 하지만 변하지 않는 것도 있답니다."
        case .greedy:
            currentDialogue = "돈이 잘 들어와서 아주 좋습니다! 하하하!"
        case .wise:
            currentDialogue = "세월이 흘러도 이 늙은 몸은 아직 건재하답니다."
        case .cheerful:
            currentDialogue = "매일매일이 즐거워요! 좋은 사람들을 만나니까 말이죠!"
            
        case .serious:
            currentDialogue = "그저 그렇습니다. 일에 집중하고 있을 뿐이에요."
            
        case .eccentric:
            currentDialogue = "아주 신나는 하루였어요! 이상한 일들이 많이 일어났거든요!"
        }
    }
    
    private func handleTrade() {
        currentDialogue = "좋습니다! 제가 가진 최고의 상품들을 보여드리죠."
        // TODO: 거래 인터페이스로 전환
    }
    
    private func handleFriendshipTalk() {
        currentDialogue = "당신과 이야기하는 것이 항상 즐겁습니다. 오랜 친구 같아요!"
    }
    
    private func handleQuestInquiry() {
        currentDialogue = "사실... 당신 같은 믿을 만한 분을 찾고 있었습니다. 들어보실래요?"
        // TODO: 퀘스트 시스템 연동
    }
    
    private func handleSpecialService() {
        currentDialogue = "친한 사이니까 특별한 서비스를 제공해드릴 수 있어요..."
        showSpecialServices = true
    }
    
    private func handleGoodbye() {
        currentDialogue = "언제든 다시 오세요! 항상 환영입니다."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            dismiss()
        }
    }
}

// MARK: - DialogueOptionButton 컴포넌트
struct DialogueOptionButton: View {
    let text: String
    let isEnabled: Bool
    let action: () -> Void
    
    init(text: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.text = text
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
        }
        .buttonStyle(DialogueOptionButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

// MARK: - Preview
#Preview {
    MerchantDialogueView(
        merchant: Merchant(
            name: "현자 오라클",
            title: "고대 지식의 수호자",
            type: .mystic,
            personality: .wise,
            district: .myeongdong,
            coordinate: CLLocationCoordinate2D(latitude: 37.5735, longitude: 126.9788),
            requiredLicense: .intermediate,
            priceModifier: 1.2,
            negotiationDifficulty: 5,
            preferredItems: ["artifact", "material"],
            dislikedItems: ["modern"],
            reputationRequirement: 100,
            friendshipLevel: 30,
            trustLevel: 0,
            appearanceId: 4,
            portraitId: 4,
            mood: .wise,
            specialAbilities: [.appraisal, .fortuneTelling],
            isQuestGiver: true
        )
    )
}
