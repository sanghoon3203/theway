// 📁 ViewModels/AchievementViewModel.swift - 업적 뷰모델
import Foundation
import Combine
import UIKit

@MainActor
class AchievementViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCompletionAlert = false
    @Published var newlyCompletedAchievement: Achievement?
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 샘플 데이터로 초기화 (개발용)
        loadSampleData()
    }
    
    // MARK: - 업적 로드
    func loadAchievements() {
        isLoading = true
        errorMessage = nil
        
        // TODO: 실제 API 연동 시 NetworkManager 사용
        // 현재는 샘플 데이터 사용
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            // 샘플 데이터는 이미 init에서 로드됨
        }
    }
    
    // MARK: - 보상 수령
    func claimReward(for achievementId: String) {
        guard let achievement = achievements.first(where: { $0.id == achievementId }),
              achievement.canClaim else {
            return
        }
        
        // TODO: 실제 API 연동
        // 현재는 로컬에서만 업데이트
        if let index = achievements.firstIndex(where: { $0.id == achievementId }) {
            achievements[index].claimed = true
            showSuccessMessage("보상을 받았습니다!")
        }
    }
    
    // MARK: - 업적 체크 (게임 플레이 중 호출)
    func checkForNewAchievements() {
        // TODO: 실제 API 연동
        // 현재는 시뮬레이션 데이터 사용
        print("업적 체크 실행됨 (현재 샘플 모드)")
    }
    
    // MARK: - Private Methods
    
    private func handleNewAchievement(_ newAchievement: NewAchievementData) {
        // 새 업적 완료 알림 표시
        if let achievement = achievements.first(where: { $0.id == newAchievement.id }) {
            newlyCompletedAchievement = achievement
            showCompletionAlert = true
        }
        
        // 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    private func showSuccessMessage(_ message: String) {
        // TODO: Toast 메시지 표시 시스템 구현
        print("성공: \(message)")
    }
    
    // MARK: - Sample Data (개발용)
    private func loadSampleData() {
        var sampleData = Achievement.sampleAchievements
        
        // 샘플 진행도 설정
        sampleData[0].currentProgress = 1
        sampleData[0].isCompleted = true
        sampleData[0].completedAt = Date()
        sampleData[0].claimed = false
        
        sampleData[1].currentProgress = 45000
        sampleData[1].isCompleted = false
        
        sampleData[2].currentProgress = 7
        sampleData[2].isCompleted = false
        
        sampleData[3].currentProgress = 1
        sampleData[3].isCompleted = true
        sampleData[3].completedAt = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        sampleData[3].claimed = true
        
        achievements = sampleData
    }
    
    // MARK: - Statistics
    var completedCount: Int {
        achievements.filter(\.isCompleted).count
    }
    
    var totalCount: Int {
        achievements.count
    }
    
    var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    func categoryProgress(for category: AchievementCategory) -> (completed: Int, total: Int) {
        let categoryAchievements = achievements.filter { $0.category == category }
        let completed = categoryAchievements.filter(\.isCompleted).count
        return (completed: completed, total: categoryAchievements.count)
    }
}

// MARK: - Response Models

struct NewAchievementResponse: Codable {
    let success: Bool
    let data: NewAchievementResponseData
}

struct NewAchievementResponseData: Codable {
    let newAchievements: [NewAchievementData]
}

struct NewAchievementData: Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let rewardType: String
    let rewardValue: String
}
