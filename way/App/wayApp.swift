//
//  wayApp.swift
//  way
//
//  Created by 김상훈 on 7/22/25.
//

import SwiftUI
import MapboxMaps

@main
struct wayApp: App {
    
    init() {
        // 네트워크 설정 출력 (개발 환경에서만)
        #if DEBUG
        NetworkConfiguration.printCurrentConfiguration()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()  // 게임 전체를 관리하는 뷰
        }
    }
}

