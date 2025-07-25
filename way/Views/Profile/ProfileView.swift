//
//  ProfileView.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Profile/ProfileView.swift - 프로필 화면
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 플레이어 정보 - 컴포넌트로 분리
                    PlayerInfoCard(player: gameManager.player)
                    
                    // 통계 카드 - 컴포넌트로 분리  
                    StatsCard(
                        money: gameManager.player.money,
                        trustPoints: gameManager.player.trustPoints,
                        tradeCount: 0, // 나중에 GameManager에서 추적
                        totalProfit: 0 // 나중에 GameManager에서 추적
                    )
                    
                    // 자산 카드 - 컴포넌트로 분리
                    AssetsCard(
                        vehicleCount: gameManager.player.vehicles.count,
                        petCount: gameManager.player.pets.count,
                        propertyCount: gameManager.player.ownedProperties.count
                    )
                    
                    // 설정 카드
                    SettingsCard()
                }
                .padding()
            }
            .navigationTitle("프로필")
        }
    }
}
