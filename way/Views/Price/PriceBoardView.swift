//
//  PriceBoardView.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


import SwiftUI

struct PriceBoardView: View {
    @EnvironmentObject var gameManager: GameManager
    @State private var searchText = ""
    @State private var selectedCategory = "전체"
    
    private let categories = ["전체", "IT부품", "명품", "예술품", "화장품", "서적", "생활용품"]
    
    var filteredItems: [(String, (district: SeoulDistrict, price: Int))] {
        let items = Array(gameManager.priceBoard)
        
        let categoryFiltered = selectedCategory == "전체" 
            ? items 
            : items.filter { $0.key.contains(selectedCategory) }
        
        let searchFiltered = searchText.isEmpty 
            ? categoryFiltered 
            : categoryFiltered.filter { $0.key.localizedCaseInsensitiveContains(searchText) }
        
        return searchFiltered.sorted { $0.1.price > $1.1.price }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 검색바
                SearchBar(text: $searchText)
                
                // 카테고리 선택
                CategorySelector(categories: categories, selectedCategory: $selectedCategory)
                
                // 가격 리스트
                List {
                    ForEach(filteredItems, id: \.0) { item, info in
                        PriceListRow(itemName: item, district: info.district, price: info.price)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("시세 정보")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// 검색바 컴포넌트
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("상품 검색", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

// 카테고리 선택 컴포넌트
struct CategorySelector: View {
    let categories: [String]
    @Binding var selectedCategory: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// 가격 리스트 행 컴포넌트
struct PriceListRow: View {
    let itemName: String
    let district: SeoulDistrict
    let price: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(itemName)
                    .font(.headline)
                
                Text(district.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(price.formatted())원")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("최고가")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
