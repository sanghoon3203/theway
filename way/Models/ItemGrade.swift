// 📁 Models/ItemGrade.swift

import SwiftUI

enum ItemGrade: String, CaseIterable, Codable {
    case common = "커먼"
    case intermediate = "중급"
    case advanced = "고급"
    case rare = "희귀"
    case legendary = "레어"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .intermediate: return .green
        case .advanced: return .blue
        case .rare: return .purple
        case .legendary: return .orange
        }
    }
}
