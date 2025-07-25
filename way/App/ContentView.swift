import SwiftUI

struct ContentView: View {
    @StateObject private var gameManager = GameManager() // 여기서 한 번만 생성!
    
    var body: some View {
        MainTabView()
            .environmentObject(gameManager) // 모든 하위 뷰에 전달
    }
}
