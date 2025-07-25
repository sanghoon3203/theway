//
//  AssetsCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Profile/Components/AssetsCard.swift
import SwiftUI

struct AssetsCard: View {
    let vehicleCount: Int
    let petCount: Int
    let propertyCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("소유 자산")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                AssetRow(title: "차량", count: vehicleCount, icon: "car.fill", color: .blue)
                
                AssetRow(title: "펫", count: petCount, icon: "pawprint.fill", color: .orange)
                
                AssetRow(title: "부동산", count: propertyCount, icon: "house.fill", color: .green)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
