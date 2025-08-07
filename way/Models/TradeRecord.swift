
// 📁 Models/TradeRecord.swift - 새 파일 생성
import Foundation

struct TradeRecord: Identifiable, Codable {
    let id = UUID()
    let itemName: String
    let itemCategory: String
    let tradeType: TradeType
    let price: Int
    let profit: Int?
    let merchantName: String
    let location: String
    let timestamp: Date
    
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
