import SwiftUI

@MainActor
@Observable
public class RestTimerManager {
    public static let shared = RestTimerManager()
    
    public var timeRemaining: Int = 0
    public var totalDuration: Int = 90
    public var isActive: Bool = false
    
    private var timer: Timer?
    
    private init() {}
    
    public func start(duration: Int) {
        totalDuration = duration
        timeRemaining = duration
        isActive = true
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timeRemaining = 0
                self.stop()
                self.triggerAlerts()
            }
        }
    }
    
    public func stop() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    public func addTime(_ seconds: Int) {
        if isActive {
            timeRemaining += seconds
            totalDuration += seconds
        } else {
            start(duration: seconds)
        }
    }
    
    private func triggerAlerts() {
        HapticsService.shared.triggerNotification(type: .success)
        SoundService.shared.playTimerAlert()
    }
}

public struct RestTimerView: View {
    @State private var timerManager = RestTimerManager.shared
    
    public init() {}
    
    public var body: some View {
        if timerManager.isActive && timerManager.timeRemaining > 0 {
            HStack(spacing: 16) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(timerManager.timeRemaining) / CGFloat(timerManager.totalDuration))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timerManager.timeRemaining)
                    
                    Text("\(timerManager.timeRemaining)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Active")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                    Text("Next set starts soon")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Adjustments
                HStack(spacing: 8) {
                    Button(action: {
                        timerManager.addTime(15)
                        HapticsService.shared.triggerImpact(style: .light)
                    }) {
                        Text("+15s")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        timerManager.stop()
                        HapticsService.shared.triggerImpact(style: .medium)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
