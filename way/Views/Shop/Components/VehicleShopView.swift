// 📁 Views/Shop/Components/VehicleShopView.swift - 수정된 버전
import SwiftUI

struct VehicleShopView: View {
    @EnvironmentObject var gameManager: GameManager
    
    // 구매 가능한 차량들 (정적 데이터)
    private let vehicles = [
        Vehicle(name: "나무 수레", type: .cart, price: 50000, inventoryBonus: 2, speedBonus: 1.1),
        Vehicle(name: "소형 트럭", type: .truck, price: 200000, inventoryBonus: 5, speedBonus: 1.3),
        Vehicle(name: "대형 트럭", type: .truck, price: 800000, inventoryBonus: 10, speedBonus: 1.5),
        Vehicle(name: "화물선", type: .ship, price: 2000000, inventoryBonus: 20, speedBonus: 2.0)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 안내 문구
                VStack(spacing: 8) {
                    Text("🚗 차량 상점")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("차량을 구매하면 인벤토리 용량과 이동 속도가 증가합니다!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // 차량 리스트 - 올바른 호출 방식
                ForEach(vehicles, id: \.id) { vehicle in
                    VehicleCard(vehicle: vehicle) {  // 이렇게 간단하게!
                        purchaseVehicle(vehicle)
                    }
                    .environmentObject(gameManager)  // 환경 객체 전달
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func purchaseVehicle(_ vehicle: Vehicle) {
        guard gameManager.player.money >= vehicle.price else { return }
        
        // 구매 처리
        gameManager.player.money -= vehicle.price
        gameManager.player.maxInventorySize += vehicle.inventoryBonus
        gameManager.player.vehicles.append(vehicle)
    }
}

