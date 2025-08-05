// 📁 Views/Shop/Components/LicenseShopView.swift
import SwiftUI

struct LicenseShopView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 안내 문구
                VStack(spacing: 8) {
                    Text("📜 라이센스 상점")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("라이센스를 업그레이드하면 더 좋은 상품을 거래할 수 있습니다!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // 현재 라이센스
                CurrentLicenseCard()
                    .environmentObject(gameManager)
                
                // 업그레이드 섹션
                if canUpgradeLicense() {
                    UpgradeAvailableCard()
                        .environmentObject(gameManager)
                } else {
                    UpgradeRequirementsCard()
                        .environmentObject(gameManager)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // 라이센스 업그레이드 가능 여부 체크
    private func canUpgradeLicense() -> Bool {
        let player = gameManager.player
        let currentLevel = player.currentLicense.rawValue
        
        // 최대 레벨이면 업그레이드 불가
        guard currentLevel < 5 else { return false }
        
        // 다음 레벨 요구사항 체크
        let nextLevel = LicenseLevel(rawValue: currentLevel + 1) ?? .master
        let requirements = getLicenseRequirements(for: nextLevel)
        
        return player.money >= requirements.requiredMoney &&
               player.trustPoints >= requirements.requiredTrust
    }
    
    // 라이센스별 요구사항 반환
    private func getLicenseRequirements(for license: LicenseLevel) -> (requiredMoney: Int, requiredTrust: Int) {
        switch license {
        case .beginner: return (0, 0)
        case .intermediate: return (100000, 50)
        case .advanced: return (500000, 200)
        case .expert: return (2000000, 500)
        case .master: return (10000000, 1000)
        }
    }
}
