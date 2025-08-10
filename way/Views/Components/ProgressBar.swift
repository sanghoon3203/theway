import SwiftUI

struct ProgressBar: View {
    let current: Int
    let total: Int
    let height: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(
        current: Int,
        total: Int,
        height: CGFloat = 8,
        backgroundColor: Color = Color.black.opacity(0.3),
        foregroundColor: Color = DesignSystem.primaryColor
    ) {
        self.current = current
        self.total = total
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return min(CGFloat(current) / CGFloat(total), 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                    .frame(height: height)
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * progress, height: height)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(current: 3, total: 10)
        ProgressBar(current: 7, total: 10, foregroundColor: .green)
        ProgressBar(current: 10, total: 10, foregroundColor: .blue)
    }
    .padding()
}