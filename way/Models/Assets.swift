// 📁 Models/Assets.swift
import Foundation
import CoreLocation

// 1. Property는 CLLocationCoordinate2D 때문에 수동 Codable 구현
struct Property: Identifiable {
    let id: String
    let name: String
    let type: PropertyType
    let district: SeoulDistrict
    let coordinate: CLLocationCoordinate2D
    let purchasePrice: Int
    let dailyIncome: Int
    var owned: Bool = false
    
    init(name: String, type: PropertyType, district: SeoulDistrict,
         coordinate: CLLocationCoordinate2D, purchasePrice: Int, dailyIncome: Int, owned: Bool = false) {
        self.id = UUID().uuidString
        self.name = name
        self.type = type
        self.district = district
        self.coordinate = coordinate
        self.purchasePrice = purchasePrice
        self.dailyIncome = dailyIncome
        self.owned = owned
    }
    
    enum PropertyType: String, CaseIterable, Codable {
        case house = "집"
        case shop = "상점"
        case warehouse = "창고"
        case farm = "농장"
    }
}

// Property에 대한 수동 Codable 구현
extension Property: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, type, district, purchasePrice, dailyIncome, owned
        case latitude, longitude
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(district, forKey: .district)
        try container.encode(purchasePrice, forKey: .purchasePrice)
        try container.encode(dailyIncome, forKey: .dailyIncome)
        try container.encode(owned, forKey: .owned)
        
        // CLLocationCoordinate2D를 개별 필드로 저장
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(PropertyType.self, forKey: .type)
        district = try container.decode(SeoulDistrict.self, forKey: .district)
        purchasePrice = try container.decode(Int.self, forKey: .purchasePrice)
        dailyIncome = try container.decode(Int.self, forKey: .dailyIncome)
        owned = try container.decode(Bool.self, forKey: .owned)
        
        // 개별 필드에서 CLLocationCoordinate2D 복원
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


struct Vehicle: Identifiable, Codable {
    let id: String // UUID() 대신 String으로 변경
    let name: String
    let type: VehicleType
    let price: Int
    let inventoryBonus: Int
    let speedBonus: Double
    var owned: Bool = false
    
    // 초기화 시 UUID 생성
    init(name: String, type: VehicleType, price: Int,
         inventoryBonus: Int, speedBonus: Double, owned: Bool = false) {
        self.id = UUID().uuidString // String으로 변환
        self.name = name
        self.type = type
        self.price = price
        self.inventoryBonus = inventoryBonus
        self.speedBonus = speedBonus
        self.owned = owned
    }
    
    enum VehicleType: String, CaseIterable, Codable {
        case cart = "수레"
        case truck = "트럭"
        case ship = "배"
    }
}

struct Pet: Identifiable, Codable {
    let id: String // UUID() 대신 String으로 변경
    let name: String
    let type: PetType
    let price: Int
    let specialAbility: String
    var owned: Bool = false
    
    // 초기화 시 UUID 생성
    init(name: String, type: PetType, price: Int,
         specialAbility: String, owned: Bool = false) {
        self.id = UUID().uuidString // String으로 변환
        self.name = name
        self.type = type
        self.price = price
        self.specialAbility = specialAbility
        self.owned = owned
    }
    
    enum PetType: String, CaseIterable, Codable {
        case horse = "말"
        case dog = "개"
        case cat = "고양이"
    }
}
