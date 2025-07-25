//
//  AssetRow.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Profile/Components/AssetRow.swift
import SwiftUI

struct AssetRow: View {
    let title: String
    let count: Int
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
            
            // 개수
            Text("\(count)개")
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
