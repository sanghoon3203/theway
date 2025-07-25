//
//  MerchantHeader.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Merchant/Components/MerchantHeader.swift
import SwiftUI

struct MerchantHeader: View {
    let merchant: Merchant
    let canTrade: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // 상인 아바타
            Circle()
                .fill(merchant.type == .retail ? .green : merchant.type == .wholesale ? .blue : .purple)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: merchant.type == .retail ? "cart" : merchant.type == .wholesale ? "building.2" : "crown")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 4) {
                Text(merchant.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(merchant.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(merchant.district.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                // 거래 상태
                HStack {
                    Circle()
                        .fill(canTrade ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(canTrade ? "거래 가능" : "라이센스 부족")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(canTrade ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }
}
