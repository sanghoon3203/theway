
// 📁 Models/SeoulDistrict.swift
import Foundation

enum SeoulDistrict: String, CaseIterable, Codable {
    case gangnam = "강남구"
    case hongdae = "마포구"
    case myeongdong = "중구"
    case itaewon = "용산구"
    case sinchon = "서대문구"
    case gangbuk = "강북구"
    
    var specialties: [String] {
        switch self {
        case .gangnam: return ["IT부품", "명품", "금융상품"]
        case .hongdae: return ["예술품", "음반", "공연용품"]
        case .myeongdong: return ["화장품", "패션", "관광상품"]
        case .itaewon: return ["수입품", "외국음식", "골동품"]
        case .sinchon: return ["서적", "문구류", "교육용품"]
        case .gangbuk: return ["생활용품", "식료품", "전통상품"]
        }
    }
    
    func priceMultiplier(for category: String) -> Double {
        if specialties.contains(category) {
            return Double.random(in: 1.2...1.8)
        } else {
            return Double.random(in: 0.8...1.2)
        }
    }
}
