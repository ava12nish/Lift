import AudioToolbox

@MainActor
public class SoundService {
    public static let shared = SoundService()
    
    private init() {}
    
    public func playTimerAlert() {
        guard UserSettingsManager.shared.soundsEnabled else { return }
        // System sound 1005 is a standard clean bell alert on iOS.
        // System sound 1304 is a clean tri-tone. Let's use 1005.
        AudioServicesPlaySystemSound(1005)
    }
    
    public func playSuccessAlert() {
        guard UserSettingsManager.shared.soundsEnabled else { return }
        AudioServicesPlaySystemSound(1325) // Nice swoosh/success chime
    }
}
