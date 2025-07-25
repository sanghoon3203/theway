//
//  SettingRow.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Profile/Components/SettingRow.swift
import SwiftUI

struct SettingRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // 아이콘
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                // 제목
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 화살표
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
