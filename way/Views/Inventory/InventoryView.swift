
// 📁 Views/Inventory/InventoryView.swift - 인벤토리 메인 화면
import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showingSellSheet = false
    @State private var selectedItem: TradeItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 상단 정보 - 컴포넌트로 분리
                InventoryHeaderCard(
                    itemCount: gameManager.player.inventory.count,
                    maxItems: gameManager.player.maxInventorySize,
                    totalValue: calculateTotalValue()
                )
                
                if gameManager.player.inventory.isEmpty {
                    // 빈 상태 - 컴포넌트로 분리
                    EmptyInventoryView()
                } else {
                    // 아이템 그리드 - 컴포넌트로 분리
                    InventoryGridView(
                        items: gameManager.player.inventory,
                        onItemTap: { item in
                            selectedItem = item
                            showingSellSheet = true
                        }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("인벤토리")
        }
        .sheet(item: $selectedItem) { item in
            SellItemSheet(item: item)
                .environmentObject(gameManager)
        }
    }
    
    private func calculateTotalValue() -> Int {
        gameManager.player.inventory.reduce(0) { $0 + $1.currentPrice }
    }
}

// =====================================
