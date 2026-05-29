import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
public class UserSettingsManager {
    public static let shared = UserSettingsManager()
    
    private init() {}
    
    public var weightUnit: WeightUnit {
        get {
            let val = UserDefaults.standard.string(forKey: "weightUnit") ?? "lb"
            return WeightUnit(rawValue: val) ?? .lb
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "weightUnit")
        }
    }
    
    public var bodyweightUnit: WeightUnit {
        get {
            let val = UserDefaults.standard.string(forKey: "bodyweightUnit") ?? "lb"
            return WeightUnit(rawValue: val) ?? .lb
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "bodyweightUnit")
        }
    }
    
    public var defaultRestSeconds: Int {
        get {
            UserDefaults.standard.object(forKey: "defaultRestSeconds") as? Int ?? 90
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "defaultRestSeconds")
        }
    }
    
    public var hapticsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "hapticsEnabled") == nil { return true }
            return UserDefaults.standard.bool(forKey: "hapticsEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "hapticsEnabled")
        }
    }
    
    public var soundsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "soundsEnabled") == nil { return true }
            return UserDefaults.standard.bool(forKey: "soundsEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "soundsEnabled")
        }
    }
    
    public var selectedTheme: String {
        get {
            UserDefaults.standard.string(forKey: "selectedTheme") ?? "Neon Lift"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedTheme")
        }
    }
    
    public var defaultShareCardStyle: ShareCardStyle {
        get {
            let val = UserDefaults.standard.string(forKey: "defaultShareCardStyle") ?? "Neon Lift"
            return ShareCardStyle(rawValue: val) ?? .neonLift
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "defaultShareCardStyle")
        }
    }
    
    public var appThemeMode: AppThemeMode {
        get {
            let val = UserDefaults.standard.string(forKey: "appThemeMode") ?? "system"
            return AppThemeMode(rawValue: val) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "appThemeMode")
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch appThemeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

public class StorageService {
    public static func preloadExercises(context: ModelContext) {
        // Check if library is already populated
        let descriptor = FetchDescriptor<Exercise>()
        if let count = try? context.fetchCount(descriptor), count > 0 {
            return // Already populated
        }
        
        let builtInExercises: [Exercise] = [
            // Chest
            Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell, trackingType: .weightReps),
            Exercise(name: "Incline Bench Press", muscleGroup: .chest, equipment: .barbell, trackingType: .weightReps),
            Exercise(name: "Dumbbell Bench Press", muscleGroup: .chest, equipment: .dumbbell, trackingType: .weightReps),
            Exercise(name: "Chest Fly", muscleGroup: .chest, equipment: .dumbbell, trackingType: .weightReps),
            Exercise(name: "Push-Up", muscleGroup: .chest, equipment: .bodyweight, trackingType: .repsOnly),
            Exercise(name: "Cable Crossover", muscleGroup: .chest, equipment: .cable, trackingType: .weightReps),
            
            // Back
            Exercise(name: "Pull-Up", muscleGroup: .back, equipment: .bodyweight, trackingType: .repsOnly),
            Exercise(name: "Lat Pulldown", muscleGroup: .back, equipment: .machine, trackingType: .weightReps),
            Exercise(name: "Barbell Row", muscleGroup: .back, equipment: .barbell, trackingType: .weightReps),
            Exercise(name: "Seated Cable Row", muscleGroup: .back, equipment: .cable, trackingType: .weightReps),
            Exercise(name: "Deadlift", muscleGroup: .back, equipment: .barbell, trackingType: .weightReps),
            
            // Legs
            Exercise(name: "Squat", muscleGroup: .legs, equipment: .barbell, trackingType: .weightReps),
            Exercise(name: "Leg Press", muscleGroup: .legs, equipment: .machine, trackingType: .weightReps),
            Exercise(name: "Romanian Deadlift", muscleGroup: .legs, equipment: .barbell, trackingType: .weightReps),
            Exercise(name: "Leg Curl", muscleGroup: .legs, equipment: .machine, trackingType: .weightReps),
            Exercise(name: "Leg Extension", muscleGroup: .legs, equipment: .machine, trackingType: .weightReps),
            Exercise(name: "Calf Raise", muscleGroup: .legs, equipment: .machine, trackingType: .weightReps),
            Exercise(name: "Lunges", muscleGroup: .legs, equipment: .dumbbell, trackingType: .weightReps),
            
            // Shoulders
            Exercise(name: "Overhead Press", muscleGroup: .shoulders, equipment: .barbell, trackingType: .weightReps),
            Exercise(name: "Dumbbell Shoulder Press", muscleGroup: .shoulders, equipment: .dumbbell, trackingType: .weightReps),
            Exercise(name: "Lateral Raise", muscleGroup: .shoulders, equipment: .dumbbell, trackingType: .weightReps),
            Exercise(name: "Rear Delt Fly", muscleGroup: .shoulders, equipment: .dumbbell, trackingType: .weightReps),
            Exercise(name: "Shrugs", muscleGroup: .shoulders, equipment: .barbell, trackingType: .weightReps),
            
            // Arms
            Exercise(name: "Barbell Curl", muscleGroup: .arms, equipment: .barbell, trackingType: .weightReps),
            Exercise(name: "Dumbbell Curl", muscleGroup: .arms, equipment: .dumbbell, trackingType: .weightReps),
            Exercise(name: "Triceps Pushdown", muscleGroup: .arms, equipment: .cable, trackingType: .weightReps),
            Exercise(name: "Skullcrusher", muscleGroup: .arms, equipment: .barbell, trackingType: .weightReps),
            Exercise(name: "Hammer Curl", muscleGroup: .arms, equipment: .dumbbell, trackingType: .weightReps),
            
            // Core
            Exercise(name: "Plank", muscleGroup: .core, equipment: .bodyweight, trackingType: .time),
            Exercise(name: "Crunch", muscleGroup: .core, equipment: .bodyweight, trackingType: .repsOnly),
            Exercise(name: "Hanging Leg Raise", muscleGroup: .core, equipment: .bodyweight, trackingType: .repsOnly),
            
            // Cardio
            Exercise(name: "Treadmill", muscleGroup: .cardio, equipment: .cardio, trackingType: .distanceTime),
            Exercise(name: "Bike", muscleGroup: .cardio, equipment: .cardio, trackingType: .distanceTime),
            Exercise(name: "Stairmaster", muscleGroup: .cardio, equipment: .cardio, trackingType: .time),
            Exercise(name: "Rowing Machine", muscleGroup: .cardio, equipment: .cardio, trackingType: .distanceTime)
        ]
        
        for exercise in builtInExercises {
            context.insert(exercise)
        }
        
        // Add a few templates by default
        preloadDefaultTemplates(context: context)
        
        // Save
        try? context.save()
    }
    
    private static func preloadDefaultTemplates(context: ModelContext) {
        let pushTemplate = WorkoutTemplate(name: "Push Day", type: .push)
        let pullTemplate = WorkoutTemplate(name: "Pull Day", type: .pull)
        let legsTemplate = WorkoutTemplate(name: "Leg Day", type: .legs)
        let fullBodyTemplate = WorkoutTemplate(name: "Full Body Day", type: .fullBody)
        
        context.insert(pushTemplate)
        context.insert(pullTemplate)
        context.insert(legsTemplate)
        context.insert(fullBodyTemplate)
        
        // Exercises for Push Day
        let e1 = TemplateExercise(exerciseName: "Bench Press", muscleGroup: .chest, trackingType: .weightReps, orderIndex: 0)
        e1.sets = [
            TemplateSet(setNumber: 1, weight: 135, reps: 10),
            TemplateSet(setNumber: 2, weight: 135, reps: 8),
            TemplateSet(setNumber: 3, weight: 135, reps: 8)
        ]
        let e2 = TemplateExercise(exerciseName: "Overhead Press", muscleGroup: .shoulders, trackingType: .weightReps, orderIndex: 1)
        e2.sets = [
            TemplateSet(setNumber: 1, weight: 95, reps: 8),
            TemplateSet(setNumber: 2, weight: 95, reps: 8)
        ]
        let e3 = TemplateExercise(exerciseName: "Triceps Pushdown", muscleGroup: .arms, trackingType: .weightReps, orderIndex: 2)
        e3.sets = [
            TemplateSet(setNumber: 1, weight: 50, reps: 12),
            TemplateSet(setNumber: 2, weight: 60, reps: 10)
        ]
        
        pushTemplate.exercises = [e1, e2, e3]
        
        // Exercises for Pull Day
        let e4 = TemplateExercise(exerciseName: "Deadlift", muscleGroup: .back, trackingType: .weightReps, orderIndex: 0)
        e4.sets = [
            TemplateSet(setNumber: 1, weight: 225, reps: 5),
            TemplateSet(setNumber: 2, weight: 275, reps: 5)
        ]
        let e5 = TemplateExercise(exerciseName: "Pull-Up", muscleGroup: .back, trackingType: .repsOnly, orderIndex: 1)
        e5.sets = [
            TemplateSet(setNumber: 1, reps: 8),
            TemplateSet(setNumber: 2, reps: 8)
        ]
        let e6 = TemplateExercise(exerciseName: "Barbell Curl", muscleGroup: .arms, trackingType: .weightReps, orderIndex: 2)
        e6.sets = [
            TemplateSet(setNumber: 1, weight: 65, reps: 10),
            TemplateSet(setNumber: 2, weight: 65, reps: 10)
        ]
        
        pullTemplate.exercises = [e4, e5, e6]
        
        // Exercises for Leg Day
        let e7 = TemplateExercise(exerciseName: "Squat", muscleGroup: .legs, trackingType: .weightReps, orderIndex: 0)
        e7.sets = [
            TemplateSet(setNumber: 1, weight: 185, reps: 8),
            TemplateSet(setNumber: 2, weight: 225, reps: 6),
            TemplateSet(setNumber: 3, weight: 225, reps: 6)
        ]
        let e8 = TemplateExercise(exerciseName: "Romanian Deadlift", muscleGroup: .legs, trackingType: .weightReps, orderIndex: 1)
        e8.sets = [
            TemplateSet(setNumber: 1, weight: 135, reps: 10),
            TemplateSet(setNumber: 2, weight: 135, reps: 10)
        ]
        let e9 = TemplateExercise(exerciseName: "Calf Raise", muscleGroup: .legs, trackingType: .weightReps, orderIndex: 2)
        e9.sets = [
            TemplateSet(setNumber: 1, weight: 100, reps: 15),
            TemplateSet(setNumber: 2, weight: 120, reps: 12)
        ]
        
        legsTemplate.exercises = [e7, e8, e9]
    }
}
