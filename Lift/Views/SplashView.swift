import SwiftUI

public struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("LIFT")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .tracking(8)
                    .foregroundColor(.primary)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
