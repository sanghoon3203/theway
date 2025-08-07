
// 📁 Models/TradeRecord.swift - 새 파일 생성
import Foundation

struct TradeRecord: Identifiable, Codable {
    let id: String
    let itemName: String
    let itemCategory: String
    let tradeType: TradeType
    let price: Int
    let profit: Int?
    let merchantName: String
    let location: String
    let timestamp: Date
    
    // 초기화 메서드 추가
    init(itemName: String, itemCategory: String, tradeType: TradeType, price: Int, profit: Int? = nil, merchantName: String, location: String, timestamp: Date = Date()) {
        self.id = UUID().uuidString
        self.itemName = itemName
        self.itemCategory = itemCategory
        self.tradeType = tradeType
        self.price = price
        self.profit = profit
        self.merchantName = merchantName
        self.location = location
        self.timestamp = timestamp
    }
    
    enum TradeType: String, CaseIterable, Codable {
        case buy = "buy"
        case sell = "sell"
        
        var displayName: String {
            switch self {
            case .buy: return "구매"
            case .sell: return "판매"
            }
        }
    }
}
