// 📁 Views/Quest/Components/QuestCard.swift
import SwiftUI

struct QuestCard: View {
    let quest: Quest
    let onAction: () -> Void
    
    var body: some View {
        ZStack {
            // 배경 이미지 (rengtangle_button을 늘려서 사용)
            Image("rengtangle_button")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
            
            // 퀘스트 내용
            VStack(alignment: .leading, spacing: 8) {
                // 퀘스트 제목과 카테고리
                HStack {
                    Text(quest.category.emoji)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(quest.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                        
                        Text(quest.description)
                            .font(.system(size: 12))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // 상태 표시
                    StatusIndicator(status: quest.status)
                }
                
                // 진행도 (필요한 경우)
                if quest.maxProgress > 1 {
                    ProgressView(value: quest.progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 4)
                    
                    Text("\(quest.progress)/\(quest.maxProgress)")
                        .font(.system(size: 10))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                // 보상 정보
                HStack {
                    Text("보상: \(quest.rewards.displayText)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.black.opacity(0.8))
                    
                    Spacer()
                    
                    // 액션 버튼
                    ActionButton(quest: quest, onAction: onAction)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            onAction()
        }
    }
}

struct StatusIndicator: View {
    let status: QuestStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(status.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(statusColor.opacity(0.1))
        )
    }
    
    var statusColor: Color {
        switch status {
        case .available: return .green
        case .active: return .blue
        case .completed: return .orange
        case .claimed: return .gray
        case .failed: return .red
        }
    }
}

struct ActionButton: View {
    let quest: Quest
    let onAction: () -> Void
    
    var body: some View {
        Button(action: onAction) {
            Text(buttonText)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(buttonColor)
                )
        }
        .disabled(!canPerformAction)
        .opacity(canPerformAction ? 1.0 : 0.6)
    }
    
    private var buttonText: String {
        switch quest.status {
        case .available: return "수락"
        case .active: return "진행중"
        case .completed: return "완료"
        case .claimed: return "완료"
        case .failed: return "실패"
        }
    }
    
    private var buttonColor: Color {
        switch quest.status {
        case .available: return .green
        case .active: return .blue
        case .completed: return .orange
        case .claimed: return .gray
        case .failed: return .red
        }
    }
    
    private var canPerformAction: Bool {
        return quest.status == .available || quest.status == .completed
    }
}

#Preview {
    VStack(spacing: 16) {
        QuestCard(
            quest: Quest(
                title: "상인에게 물건을 구입하라",
                description: "서울 시내의 상인에게서 아무 물건이나 한 개를 구입하세요.",
                rewards: QuestReward(experience: 20, money: 1000),
                requirements: QuestRequirement(),
                category: .trading
            ),
            onAction: {}
        )
        
        QuestCard(
            quest: Quest(
                title: "강남 지역 탐험",
                description: "강남구의 상인 3명을 만나보세요.",
                rewards: QuestReward(experience: 30, money: 2000),
                requirements: QuestRequirement(),
                status: .active,
                category: .exploration,
                progress: 1,
                maxProgress: 3
            ),
            onAction: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}