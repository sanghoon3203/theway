// 📁 Views/Quest/QuestView.swift
import SwiftUI

struct QuestView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedCategory: QuestCategory? = nil
    @State private var quests: [Quest] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.91),
                        Color(red: 0.94, green: 0.91, blue: 0.85)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 페이지 타이틀
                        HStack {
                            Text("오늘의 퀘스트")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black.opacity(0.8))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 퀘스트 목록
                        LazyVStack(spacing: 16) {
                            ForEach(filteredQuests) { quest in
                                QuestCard(quest: quest) {
                                    handleQuestAction(quest)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .onAppear {
            loadQuests()
        }
    }
    
    var filteredQuests: [Quest] {
        if let category = selectedCategory {
            return quests.filter { $0.category == category }
        }
        return quests
    }
    
    private func loadQuests() {
        // 샘플 퀘스트 생성
        quests = [
            Quest(
                title: "상인에게 물건을 구입하라",
                description: "서울 시내의 상인에게서 아무 물건이나 한 개를 구입하세요.",
                rewards: QuestReward(experience: 20, money: 1000, trustPoints: 1),
                requirements: QuestRequirement(minimumLevel: 1),
                category: .trading,
                maxProgress: 1
            ),
            Quest(
                title: "첫 번째 판매 완료",
                description: "인벤토리의 아이템을 상인에게 판매해보세요.",
                rewards: QuestReward(experience: 25, money: 1500, trustPoints: 2),
                requirements: QuestRequirement(minimumLevel: 1),
                category: .trading,
                maxProgress: 1
            ),
            Quest(
                title: "강남 지역 탐험",
                description: "강남구의 상인 3명을 만나보세요.",
                rewards: QuestReward(experience: 30, money: 2000, trustPoints: 1),
                requirements: QuestRequirement(minimumLevel: 2),
                category: .exploration,
                maxProgress: 3
            ),
            Quest(
                title: "수집가의 의뢰",
                description: "희귀한 IT부품을 3개 모아오세요.",
                rewards: QuestReward(experience: 50, money: 5000, trustPoints: 3),
                requirements: QuestRequirement(minimumLevel: 3, requiredLicense: .intermediate),
                category: .collection,
                maxProgress: 3
            ),
            Quest(
                title: "신뢰 관계 구축",
                description: "한 상인과의 신뢰도를 50 이상 쌓으세요.",
                rewards: QuestReward(experience: 40, money: 3000, trustPoints: 5),
                requirements: QuestRequirement(minimumLevel: 2),
                category: .merchant,
                maxProgress: 1
            )
        ]
    }
    
    private func handleQuestAction(_ quest: Quest) {
        switch quest.status {
        case .available:
            acceptQuest(quest)
        case .completed:
            claimReward(quest)
        case .active, .claimed, .failed:
            break
        }
    }
    
    private func acceptQuest(_ quest: Quest) {
        if let index = quests.firstIndex(where: { $0.id == quest.id }) {
            quests[index].status = .active
            
            // TODO: GameManager에 활성 퀘스트 추가
            print("퀘스트 수락: \(quest.title)")
        }
    }
    
    private func claimReward(_ quest: Quest) {
        if let index = quests.firstIndex(where: { $0.id == quest.id }) {
            quests[index].status = .claimed
            
            // 보상 지급
            gameManager.player.money += quest.rewards.money
            gameManager.player.trustPoints += quest.rewards.trustPoints
            gameManager.player.addExperience(quest.rewards.experience)
            
            print("퀘스트 완료 및 보상 수령: \(quest.title)")
        }
    }
}

#Preview {
    QuestView()
        .environmentObject(GameManager())
}