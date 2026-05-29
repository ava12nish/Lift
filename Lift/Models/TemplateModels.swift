import Foundation
import SwiftData

@Model
public class WorkoutTemplate {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var typeString: String
    public var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    public var exercises: [TemplateExercise] = []
    
    public var type: WorkoutType {
        get { WorkoutType(rawValue: typeString) ?? .custom }
        set { typeString = newValue.rawValue }
    }
    
    public init(id: UUID = UUID(), name: String, type: WorkoutType = .custom, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.typeString = type.rawValue
        self.createdAt = createdAt
    }
}

@Model
public class TemplateExercise {
    @Attribute(.unique) public var id: UUID
    public var exerciseName: String
    public var muscleGroupString: String
    public var trackingTypeString: String
    
    @Relationship(deleteRule: .cascade, inverse: \TemplateSet.templateExercise)
    public var sets: [TemplateSet] = []
    
    public var orderIndex: Int
    public var template: WorkoutTemplate?
    
    public var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupString) ?? .chest }
        set { muscleGroupString = newValue.rawValue }
    }
    
    public var trackingType: TrackingType {
        get { TrackingType(rawValue: trackingTypeString) ?? .weightReps }
        set { trackingTypeString = newValue.rawValue }
    }
    
    public init(id: UUID = UUID(), exerciseName: String = "", muscleGroup: MuscleGroup = .chest, trackingType: TrackingType = .weightReps, orderIndex: Int = 0) {
        self.id = id
        self.exerciseName = exerciseName
        self.muscleGroupString = muscleGroup.rawValue
        self.trackingTypeString = trackingType.rawValue
        self.orderIndex = orderIndex
    }
}

@Model
public class TemplateSet {
    @Attribute(.unique) public var id: UUID
    public var setNumber: Int
    public var weight: Double
    public var reps: Int
    public var durationSeconds: TimeInterval
    public var distance: Double
    public var isWarmup: Bool
    
    public var templateExercise: TemplateExercise?
    
    public init(id: UUID = UUID(), setNumber: Int = 1, weight: Double = 0, reps: Int = 0, durationSeconds: TimeInterval = 0, distance: Double = 0, isWarmup: Bool = false) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.distance = distance
        self.isWarmup = isWarmup
    }
}
