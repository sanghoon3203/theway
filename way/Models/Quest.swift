// 📁 Models/Quest.swift
import Foundation

struct Quest: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let rewards: QuestReward
    let requirements: QuestRequirement
    var status: QuestStatus
    let category: QuestCategory
    var progress: Int
    let maxProgress: Int
    let createdAt: Date
    var completedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        rewards: QuestReward,
        requirements: QuestRequirement,
        status: QuestStatus = .available,
        category: QuestCategory,
        progress: Int = 0,
        maxProgress: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.rewards = rewards
        self.requirements = requirements
        self.status = status
        self.category = category
        self.progress = progress
        self.maxProgress = maxProgress
        self.createdAt = createdAt
        self.completedAt = nil
    }
    
    var isCompleted: Bool {
        return progress >= maxProgress
    }
    
    var progressPercentage: Double {
        guard maxProgress > 0 else { return 0.0 }
        return min(Double(progress) / Double(maxProgress), 1.0)
    }
}

enum QuestStatus: String, CaseIterable, Codable {
    case available = "available"    // 수락 가능
    case active = "active"         // 진행 중
    case completed = "completed"   // 완료
    case claimed = "claimed"       // 보상 수령
    case failed = "failed"         // 실패
    
    var displayName: String {
        switch self {
        case .available: return "수락 가능"
        case .active: return "진행 중"
        case .completed: return "완료"
        case .claimed: return "보상 수령"
        case .failed: return "실패"
        }
    }
}

enum QuestCategory: String, CaseIterable, Codable {
    case trading = "trading"       // 거래 퀘스트
    case exploration = "exploration" // 탐험 퀘스트
    case merchant = "merchant"     // 상인 관계 퀘스트
    case collection = "collection" // 수집 퀘스트
    case daily = "daily"          // 일일 퀘스트
    case weekly = "weekly"        // 주간 퀘스트
    case story = "story"          // 스토리 퀘스트
    
    var displayName: String {
        switch self {
        case .trading: return "거래"
        case .exploration: return "탐험"
        case .merchant: return "상인"
        case .collection: return "수집"
        case .daily: return "일일"
        case .weekly: return "주간"
        case .story: return "스토리"
        }
    }
    
    var emoji: String {
        switch self {
        case .trading: return "💰"
        case .exploration: return "🗺️"
        case .merchant: return "🤝"
        case .collection: return "📦"
        case .daily: return "📅"
        case .weekly: return "🗓️"
        case .story: return "📜"
        }
    }
}

struct QuestReward: Codable {
    let experience: Int
    let money: Int
    let items: [String]
    let trustPoints: Int
    
    init(experience: Int = 0, money: Int = 0, items: [String] = [], trustPoints: Int = 0) {
        self.experience = experience
        self.money = money
        self.items = items
        self.trustPoints = trustPoints
    }
    
    var displayText: String {
        var rewards: [String] = []
        
        if experience > 0 {
            rewards.append("\(experience)exp")
        }
        
        if money > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let formattedMoney = formatter.string(from: NSNumber(value: money)) ?? "\(money)"
            rewards.append("\(formattedMoney)원")
        }
        
        if trustPoints > 0 {
            rewards.append("신뢰도 +\(trustPoints)")
        }
        
        if !items.isEmpty {
            rewards.append(contentsOf: items)
        }
        
        return rewards.joined(separator: ", ")
    }
}

struct QuestRequirement: Codable {
    let minimumLevel: Int
    let requiredItems: [String]
    let requiredLicense: LicenseLevel
    let prerequisiteQuests: [String]
    
    init(
        minimumLevel: Int = 1,
        requiredItems: [String] = [],
        requiredLicense: LicenseLevel = .beginner,
        prerequisiteQuests: [String] = []
    ) {
        self.minimumLevel = minimumLevel
        self.requiredItems = requiredItems
        self.requiredLicense = requiredLicense
        self.prerequisiteQuests = prerequisiteQuests
    }
    
    func canAccept(player: Player, completedQuests: Set<String>) -> Bool {
        // 레벨 체크
        if player.level < minimumLevel {
            return false
        }
        
        // 라이선스 체크
        if player.currentLicense.rawValue < requiredLicense.rawValue {
            return false
        }
        
        // 필수 아이템 체크
        for requiredItem in requiredItems {
            if !player.inventory.contains(where: { $0.name == requiredItem }) {
                return false
            }
        }
        
        // 선행 퀘스트 체크
        for prerequisite in prerequisiteQuests {
            if !completedQuests.contains(prerequisite) {
                return false
            }
        }
        
        return true
    }
}