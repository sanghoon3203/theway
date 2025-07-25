//
//  LicenseShopView.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


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
                if gameManager.player.canUpgradeLicense() {
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
}