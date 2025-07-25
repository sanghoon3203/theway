// 📁 Models/Merchant.swift
import Foundation
import CoreLocation

struct Merchant: Identifiable {
    let id: String  // UUID() → String으로 변경
    let name: String
    let type: MerchantType
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    let requiredLicense: LicenseLevel
    var inventory: [TradeItem]
    var trustLevel: Int
    
    // 초기화 메서드 추가
    init(name: String, type: MerchantType, district: SeoulDistrict,
         coordinate: CLLocationCoordinate2D, requiredLicense: LicenseLevel,
         inventory: [TradeItem], trustLevel: Int = 0) {
        self.id = UUID().uuidString  // String으로 변환
        self.name = name
        self.type = type
        self.district = district
        self.coordinate = coordinate
        self.requiredLicense = requiredLicense
        self.inventory = inventory
        self.trustLevel = trustLevel
    }
    
    enum MerchantType: String, CaseIterable, Codable {  // Codable 추가
        case retail = "말단상인"
        case wholesale = "중간상인"
        case premium = "중요대상인"
        
        var maxItemGrade: ItemGrade {
            switch self {
            case .retail: return .intermediate
            case .wholesale: return .rare
            case .premium: return .legendary
            }
        }
    }
}

// Merchant에 대한 수동 Codable 구현
extension Merchant: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, type, district, requiredLicense, inventory, trustLevel
        case latitude, longitude
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(district, forKey: .district)
        try container.encode(requiredLicense, forKey: .requiredLicense)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(trustLevel, forKey: .trustLevel)
        
        // CLLocationCoordinate2D를 개별 필드로 저장
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(MerchantType.self, forKey: .type)
        district = try container.decode(SeoulDistrict.self, forKey: .district)
        requiredLicense = try container.decode(LicenseLevel.self, forKey: .requiredLicense)
        inventory = try container.decode([TradeItem].self, forKey: .inventory)
        trustLevel = try container.decode(Int.self, forKey: .trustLevel)
        
        // 개별 필드에서 CLLocationCoordinate2D 복원
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
