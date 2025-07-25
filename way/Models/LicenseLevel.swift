// 📁 Models/LicenseLevel.swift
import Foundation

enum LicenseLevel: Int, CaseIterable, Codable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3
    case expert = 4
    case master = 5
    
    var title: String {
        switch self {
        case .beginner: return "견습 상인"
        case .intermediate: return "일반 상인"
        case .advanced: return "숙련 상인"
        case .expert: return "전문 상인"
        case .master: return "마스터 상인"
        }
    }
    
    var requiredMoney: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 100000
        case .advanced: return 500000
        case .expert: return 2000000
        case .master: return 10000000
        }
    }
    
    var requiredTrust: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 50
        case .advanced: return 200
        case .expert: return 500
        case .master: return 1000
        }
    }
}

