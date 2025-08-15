
// 📁 Views/Inventory/InventoryView.swift - 수묵화 스타일 인벤토리 화면
import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var showingSellSheet = false
    @State private var selectedItem: TradeItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                // 수묵화 배경
                LinearGradient.paperBackground
                    .ignoresSafeArea()
                
                // 배경 산 실루엣
                VStack {
                    Spacer()
                    MountainSilhouette()
                        .frame(height: 100)
                        .opacity(0.08)
                }
                
                // 은은한 먹 점 패턴
                InkDotPattern()
                    .opacity(0.06)
                
                VStack(spacing: 20) {
                    // 수묵화 스타일 상단 정보
                    InkInventoryHeaderCard(
                        itemCount: gameManager.player.inventory.count,
                        maxItems: gameManager.player.maxInventorySize,
                        totalValue: calculateTotalValue()
                    )
                    
                    if gameManager.player.inventory.isEmpty {
                        // 빈 상태 - 수묵화 스타일
                        InkEmptyInventoryView()
                    } else {
                        // 아이템 그리드 - 수묵화 스타일
                        InkInventoryGridView(
                            items: gameManager.player.inventory,
                            onItemTap: { item in
                                selectedItem = item
                                showingSellSheet = true
                            }
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("보관소")
            .navigationBarTitleDisplayMode(.large)
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

// MARK: - 수묵화 스타일 인벤토리 헤더 카드
struct InkInventoryHeaderCard: View {
    let itemCount: Int
    let maxItems: Int
    let totalValue: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                Text("소지품 현황")
                    .font(.brushStroke)
                    .foregroundColor(.brushText)
                
                Spacer()
                
                Text("\(itemCount) / \(maxItems)")
                    .font(.inkText)
                    .foregroundColor(.fadeText)
            }
            
            // 용량 표시 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.inkMist.opacity(0.3))
                        .frame(height: 12)
                    
                    // 진행률
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: itemCount >= maxItems ? 
                                [Color.compass.opacity(0.7), Color.compass] : 
                                [Color.brushText.opacity(0.6), Color.brushText],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * min(Double(itemCount) / Double(maxItems), 1.0),
                            height: 12
                        )
                        .animation(.easeInOut(duration: 0.3), value: itemCount)
                }
            }
            .frame(height: 12)
            
            // 총 가치
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.brushText.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text("총 가치")
                        .font(.inkText)
                        .foregroundColor(.brushText)
                }
                
                Spacer()
                
                Text("\(totalValue) 전")
                    .font(.brushStroke)
                    .fontWeight(.medium)
                    .foregroundColor(.brushText)
            }
        }
        .inkCard()
    }
}

// MARK: - 수묵화 스타일 빈 인벤토리 뷰
struct InkEmptyInventoryView: View {
    var body: some View {
        VStack(spacing: 24) {
            // 빈 상태 아이콘
            ZStack {
                Circle()
                    .fill(Color.softWhite)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.inkBlack.opacity(0.2), lineWidth: 2)
                    )
                
                Image(systemName: "bag")
                    .font(.system(size: 60))
                    .foregroundColor(.brushText.opacity(0.5))
            }
            .shadow(color: Color.inkMist.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 12) {
                Text("보관소가 비어있습니다")
                    .font(.brushStroke)
                    .foregroundColor(.brushText)
                
                Text("상인들과 거래하여 물건을 수집해보세요")
                    .font(.inkText)
                    .foregroundColor(.fadeText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .inkCard()
    }
}

// MARK: - 수묵화 스타일 인벤토리 그리드 뷰
struct InkInventoryGridView: View {
    let items: [TradeItem]
    let onItemTap: (TradeItem) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items, id: \.id) { item in
                    InkInventoryItemCard(
                        item: item,
                        onTap: { onItemTap(item) }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - 수묵화 스타일 인벤토리 아이템 카드
struct InkInventoryItemCard: View {
    let item: TradeItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 아이템 아이콘 영역
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.softWhite)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.inkBlack.opacity(0.1), lineWidth: 1)
                        )
                    
                    // 임시 아이콘 (실제로는 아이템 이미지)
                    Image(systemName: itemIcon(for: item.category))
                        .font(.system(size: 32))
                        .foregroundColor(.brushText.opacity(0.7))
                }
                
                // 아이템 정보
                VStack(spacing: 4) {
                    Text(item.name)
                        .font(.inkText)
                        .fontWeight(.medium)
                        .foregroundColor(.brushText)
                        .lineLimit(1)
                    
                    Text("\(item.currentPrice) 전")
                        .font(.whisperText)
                        .foregroundColor(.fadeText)
                    
                    // 수량 (여러 개인 경우)
                    if item.quantity > 1 {
                        Text("x\(item.quantity)")
                            .font(.whisperText)
                            .foregroundColor(.brushText.opacity(0.6))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.softWhite.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.inkBlack.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.inkMist.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func itemIcon(for category: String) -> String {
        switch category.lowercased() {
        case "electronics": return "laptopcomputer"
        case "food": return "leaf.fill"
        case "clothing": return "tshirt.fill"
        case "books": return "book.fill"
        case "tools": return "wrench.fill"
        case "medicine": return "pills.fill"
        default: return "cube.box.fill"
        }
    }
}

// =====================================
