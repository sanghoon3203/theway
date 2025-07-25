//
//  StatRow.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Profile/Components/StatRow.swift
import SwiftUI

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            // 아이콘
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            // 제목
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // 값
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
