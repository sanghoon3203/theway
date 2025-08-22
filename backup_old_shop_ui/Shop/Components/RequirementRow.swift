//
//  RequirementRow.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Shop/Components/RequirementRow.swift
import SwiftUI

struct RequirementRow: View {
    let title: String
    let current: Int
    let required: Int
    let isMet: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(current.formatted()) / \(required.formatted())")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isMet ? .green : .red)
            
            Image(systemName: isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isMet ? .green : .red)
        }
    }
}
