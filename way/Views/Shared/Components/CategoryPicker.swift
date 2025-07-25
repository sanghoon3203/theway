//
//  CategoryPicker.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Shared/Components/CategoryPicker.swift - 재사용 가능한 컴포넌트
import SwiftUI

struct CategoryPicker: View {
    let categories: [String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        Picker("Category", selection: $selectedIndex) {
            ForEach(0..<categories.count, id: \.self) { index in
                Text(categories[index]).tag(index)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}
