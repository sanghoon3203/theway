//
//  LicenseWarning.swift
//  way
//
//  Created by 김상훈 on 7/24/25.
//


// 📁 Views/Merchant/Components/LicenseWarning.swift
import SwiftUI

struct LicenseWarning: View {
    let requiredLicense: LicenseLevel
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(.orange)
            
            Text("이 상인과 거래하려면 \(requiredLicense.title) 라이센스가 필요합니다.")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// =====================================