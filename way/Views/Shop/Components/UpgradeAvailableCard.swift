//
//  UpgradeAvailableCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Shop/Components/UpgradeAvailableCard.swift
import SwiftUI

struct UpgradeAvailableCard: View {
    @EnvironmentObject var gameManager: GameManager
    
    private var nextLicense: LicenseLevel {
        LicenseLevel(rawValue: gameManager.player.currentLicense.rawValue + 1) ?? .master
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("업그레이드 가능! 🎉")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text(nextLicense.title)
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("비용:")
                    Spacer()
                    Text("\(nextLicense.requiredMoney.formatted())원")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("필요 신뢰도:")
                    Spacer()
                    Text("\(nextLicense.requiredTrust)")
                        .fontWeight(.medium)
                }
            }
            .font(.subheadline)
            
            Button("라이센스 업그레이드") {
                let success = gameManager.player.upgradeLicense()
                if success {
                    // 업그레이드 성공 피드백
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .fontWeight(.bold)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}