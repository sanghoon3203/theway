//
//  MainTabView.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//




// 📁 Views/MainTabView.swift - 탭뷰 네비게이션
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var gameManager: GameManager // GameManager 받아오기
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 지도 화면
            MapView()
                .environmentObject(gameManager) // 다시 전달
                .tabItem {
                    Image(systemName: "map")
                    Text("지도")
                }
                .tag(0)
            
            // 2. 시세 화면
            PriceBoardView()
                .environmentObject(gameManager)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("시세")
                }
                .tag(1)
            
            // 3. 인벤토리
            InventoryView()
                .environmentObject(gameManager)
                .tabItem {
                    Image(systemName: "bag")
                    Text("인벤토리")
                }
                .tag(2)
            
            // 4. 상점
            ShopView()
                .environmentObject(gameManager)
                .tabItem {
                    Image(systemName: "storefront")
                    Text("상점")
                }
                .tag(3)
            
            // 5. 프로필
            ProfileView()
                .environmentObject(gameManager)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("프로필")
                }
                .tag(4)
        }
    }
}
