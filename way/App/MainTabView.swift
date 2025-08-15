//
//  MainTabView.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//




// 📁 Views/MainTabView.swift - 수묵화 스타일 탭뷰 네비게이션
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedTab = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 수묵화 배경
                LinearGradient.paperBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 메인 콘텐츠 영역
                    ZStack {
                        switch selectedTab {
                        case 0:
                            MapView()
                                .environmentObject(gameManager)
                        case 1:
                            PriceBoardView()
                                .environmentObject(gameManager)
                        case 2:
                            InventoryView()
                                .environmentObject(gameManager)
                        case 3:
                            CharacterView(gameManager: gameManager)
                        case 4:
                            ShopView()
                                .environmentObject(gameManager)
                        default:
                            MapView()
                                .environmentObject(gameManager)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // 커스텀 수묵화 탭바
                    InkTabBar(selectedTab: $selectedTab)
                }
            }
        }
    }
}

// MARK: - 수묵화 스타일 커스텀 탭바
struct InkTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        TabItem(icon: "map.fill", title: "지도", tag: 0),
        TabItem(icon: "chart.line.uptrend.xyaxis", title: "시세", tag: 1),
        TabItem(icon: "bag.fill", title: "인벤토리", tag: 2),
        TabItem(icon: "person.crop.circle", title: "캐릭터", tag: 3),
        TabItem(icon: "house.fill", title: "거처", tag: 4)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 구분선 - 수묵화 스타일
            Rectangle()
                .fill(Color.inkMist)
                .frame(height: 1)
            
            // 탭바 메인 영역
            HStack(spacing: 0) {
                ForEach(tabs, id: \.tag) { tab in
                    InkTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab.tag
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab.tag
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                // 탭바 배경 - 반투명 한지색
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.softWhite.opacity(0.95))
                    .shadow(color: Color.inkMist.opacity(0.3), radius: 8, x: 0, y: -4)
            )
        }
    }
}

// MARK: - 탭 아이템 데이터 모델
struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}

// MARK: - 수묵화 스타일 탭 버튼
struct InkTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // 아이콘
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .brushText : .fadeText)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                // 타이틀
                Text(tab.title)
                    .font(.whisperText)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? .brushText : .fadeText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                // 선택된 탭 배경
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.inkMist.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.inkBlack.opacity(0.1) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
