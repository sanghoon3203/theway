//
//  VehicleCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Shop/Components/VehicleCard.swift
import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle
    let action: () -> Void
    @EnvironmentObject var gameManager: GameManager
    
    private var canAfford: Bool {
        gameManager.player.money >= vehicle.price
    }
    
    private var alreadyOwned: Bool {
        gameManager.player.vehicles.contains { $0.name == vehicle.name }
    }
    
    var body: some View {
        HStack {
            // 차량 아이콘
            VStack {
                Image(systemName: vehicleIcon(for: vehicle.type))
                    .font(.system(size: 30))
                    .foregroundColor(vehicleColor(for: vehicle.type))
                
                Text(vehicle.type.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            // 차량 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "bag.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("용량 +\(vehicle.inventoryBonus)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("속도 +\(Int((vehicle.speedBonus - 1.0) * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // 가격 및 구매 버튼
            VStack(alignment: .trailing, spacing: 8) {
                Text("\(vehicle.price.formatted())원")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(canAfford ? .primary : .red)
                
                if alreadyOwned {
                    Text("보유중")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                        .font(.caption)
                } else {
                    Button("구매") {
                        action()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canAfford ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(!canAfford)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func vehicleIcon(for type: Vehicle.VehicleType) -> String {
        switch type {
        case .cart: return "cart"
        case .truck: return "truck.box"
        case .ship: return "ferry"
        }
    }
    
    private func vehicleColor(for type: Vehicle.VehicleType) -> Color {
        switch type {
        case .cart: return .brown
        case .truck: return .blue
        case .ship: return .cyan
        }
    }
}
