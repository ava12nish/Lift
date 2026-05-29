import UIKit

@MainActor
public class HapticsService {
    public static let shared = HapticsService()
    
    private init() {}
    
    public func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard UserSettingsManager.shared.hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    public func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserSettingsManager.shared.hapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
