//
//  PropertyShopView.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Shop/Components/PropertyShopView.swift
import SwiftUI

struct PropertyShopView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 안내 문구
                VStack(spacing: 8) {
                    Text("🏢 부동산 상점")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("부동산은 매일 자동으로 수익을 창출합니다!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // 준비중 메시지
                VStack(spacing: 16) {
                    Image(systemName: "building.2")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("부동산 구매 준비중")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("지도에서 구매 가능한 건물을 확인하세요!\n각 지역의 랜드마크를 터치하여 부동산을 구매할 수 있습니다.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("지도에서 확인하기") {
                        // TODO: 지도 탭으로 이동
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}