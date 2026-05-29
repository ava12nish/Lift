import Foundation

public enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    case custom = "Custom"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .push: return "arrow.up.forward.square.fill"
        case .pull: return "arrow.down.backward.square.fill"
        case .legs: return "shoeprints.fill"
        case .chest: return "laurel.leading"
        case .back: return "figure.back.strength"
        case .shoulders: return "figure.arms.open"
        case .arms: return "figure.strengthtraining.traditional"
        case .fullBody: return "figure.core.training"
        case .cardio: return "figure.run"
        case .custom: return "slider.horizontal.3"
        }
    }
}

public enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case cardio = "Cardio"
    
    public var id: String { rawValue }
}

public enum EquipmentType: String, Codable, CaseIterable, Identifiable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case bodyweight = "Bodyweight"
    case cardio = "Cardio"
    case other = "Other"
    
    public var id: String { rawValue }
}

public enum TrackingType: String, Codable, CaseIterable, Identifiable {
    case weightReps = "Weight & Reps"
    case repsOnly = "Reps Only"
    case time = "Time Only"
    case distanceTime = "Distance & Time"
    
    public var id: String { rawValue }
}

public enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case lb = "lb"
    case kg = "kg"
    
    public var id: String { rawValue }
}

public enum ShareCardType: String, Codable, CaseIterable, Identifiable {
    case workout = "Workout Summary"
    case pr = "PR Achievement"
    case weekly = "Weekly Recap"
    case bodyweight = "Bodyweight Trend"
    case streak = "Streak Milestone"
    
    public var id: String { rawValue }
}

public enum ShareCardStyle: String, Codable, CaseIterable, Identifiable {
    case darkPremium = "Dark Premium"
    case neonLift = "Neon Lift"
    case minimalWhite = "Minimal White"
    case performanceStats = "Performance Stats"
    case prCelebration = "PR Celebration"
    
    public var id: String { rawValue }
}
