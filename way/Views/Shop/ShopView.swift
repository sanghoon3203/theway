
// 📁 Views/Shop/ShopView.swift - 상점 메인 화면
import SwiftUI

struct ShopView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var selectedCategory = 0
    
    private let categories = ["차량", "펫", "부동산", "라이센스"]
    
    var body: some View {
        NavigationView {
            VStack {
                // 카테고리 선택 - 컴포넌트로 분리
                CategoryPicker(
                    categories: categories,
                    selectedIndex: $selectedCategory
                )
                
                // 선택된 카테고리 내용
                Group {
                    switch selectedCategory {
                    case 0:
                        VehicleShopView()
                    case 1:
                        PetShopView()
                    case 2:
                        PropertyShopView()
                    case 3:
                        LicenseShopView()
                    default:
                        EmptyView()
                    }
                }
                .environmentObject(gameManager) // 하위 뷰에 전달
                
                Spacer()
            }
            .navigationTitle("상점")
        }
    }
}
