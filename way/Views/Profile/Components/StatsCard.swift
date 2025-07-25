//
//  StatsCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Profile/Components/StatsCard.swift
import SwiftUI

struct StatsCard: View {
    let money: Int
    let trustPoints: Int
    let tradeCount: Int
    let totalProfit: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("통계")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                StatRow(title: "보유 자금", value: "\(money.formatted())원", icon: "wonsign.circle.fill", color: .green)
                
                StatRow(title: "신뢰도", value: "\(trustPoints)", icon: "star.fill", color: .yellow)
                
                StatRow(title: "거래 횟수", value: "\(tradeCount)회", icon: "arrow.left.arrow.right", color: .blue)
                
                StatRow(title: "총 수익", value: "\(totalProfit.formatted())원", icon: "chart.line.uptrend.xyaxis", color: .purple)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}