//
//  UpgradeRequirementsCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Shop/Components/UpgradeRequirementsCard.swift
import SwiftUI

struct UpgradeRequirementsCard: View {
    @EnvironmentObject var gameManager: GameManager
    
    private var nextLicense: LicenseLevel? {
        LicenseLevel(rawValue: gameManager.player.currentLicense.rawValue + 1)
    }
    
    var body: some View {
        if let next = nextLicense {
            VStack(spacing: 16) {
                Text("다음 라이센스")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(next.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    RequirementRow(
                        title: "필요 자금",
                        current: gameManager.player.money,
                        required: next.requiredMoney,
                        isMet: gameManager.player.money >= next.requiredMoney
                    )
                    
                    RequirementRow(
                        title: "필요 신뢰도",
                        current: gameManager.player.trustPoints,
                        required: next.requiredTrust,
                        isMet: gameManager.player.trustPoints >= next.requiredTrust
                    )
                }
                
                Text("더 많은 거래를 통해 자금과 신뢰도를 쌓아보세요!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        } else {
            VStack(spacing: 16) {
                Text("🏆 최고 라이센스")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("축하합니다! 이미 최고 등급의 라이센스를 보유하고 있습니다.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
        }
    }
}
