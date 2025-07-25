
// 📁 Views/Inventory/Components/InventoryGridView.swift
import SwiftUI

struct InventoryGridView: View {
    let items: [TradeItem]
    let onItemTap: (TradeItem) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    InventoryItemCard(item: item) {
                        onItemTap(item)
                    }
                }
            }
        }
    }
}
