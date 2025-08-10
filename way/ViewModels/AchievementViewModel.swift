// 📁 ViewModels/AchievementViewModel.swift - 업적 뷰모델
import Foundation
import Combine

@MainActor
class AchievementViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showCompletionAlert = false
    @Published var newlyCompletedAchievement: Achievement?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 샘플 데이터로 초기화 (개발용)
        loadSampleData()
    }
    
    // MARK: - 업적 로드
    func loadAchievements() {
        isLoading = true
        errorMessage = nil
        
        apiService.request(
            endpoint: "/api/game/achievements/progress",
            method: .GET,
            responseType: AchievementProgressResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    print("업적 로드 실패: \(error)")
                }
            },
            receiveValue: { [weak self] response in
                if response.success {
                    self?.achievements = response.data.map { Achievement(from: $0) }
                } else {
                    self?.errorMessage = "업적을 불러올 수 없습니다."
                }
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - 보상 수령
    func claimReward(for achievementId: String) {
        guard let achievement = achievements.first(where: { $0.id == achievementId }),
              achievement.canClaim else {
            return
        }
        
        apiService.request(
            endpoint: "/api/game/achievements/\(achievementId)/claim",
            method: .POST,
            responseType: AchievementClaimResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("보상 수령 실패: \(error)")
                }
            },
            receiveValue: { [weak self] response in
                if response.success {
                    // 로컬에서 업적 상태 업데이트
                    if let index = self?.achievements.firstIndex(where: { $0.id == achievementId }) {
                        self?.achievements[index].claimed = true
                    }
                    
                    // 성공 메시지 표시
                    self?.showSuccessMessage(response.data?.message ?? "보상을 받았습니다!")
                } else {
                    self?.errorMessage = response.error ?? "보상 수령에 실패했습니다."
                }
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - 업적 체크 (게임 플레이 중 호출)
    func checkForNewAchievements() {
        apiService.request(
            endpoint: "/api/game/achievements/check",
            method: .POST,
            responseType: NewAchievementResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("업적 체크 실패: \(error)")
                }
            },
            receiveValue: { [weak self] response in
                if response.success, !response.data.newAchievements.isEmpty {
                    // 새로 완료된 업적들 처리
                    for newAchievement in response.data.newAchievements {
                        self?.handleNewAchievement(newAchievement)
                    }
                    
                    // 업적 목록 새로고침
                    self?.loadAchievements()
                }
            }
        )
        .store(in: &cancellables)
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