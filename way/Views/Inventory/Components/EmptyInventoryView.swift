//
//  EmptyInventoryView.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


import SwiftUI

struct EmptyInventoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            // 빈 인벤토리 아이콘
            Image(systemName: "bag")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            // 메인 메시지
            Text("인벤토리가 비어있습니다")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // 안내 메시지
            Text("상인을 찾아 상품을 구매해보세요!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 안내 버튼 (옵션)
            Button("지도에서 상인 찾기") {
                // TODO: 지도 탭으로 이동하는 기능 추가 가능
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 10)
        }
        .padding()
    }
}
