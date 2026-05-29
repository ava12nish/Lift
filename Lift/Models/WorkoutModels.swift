import Foundation
import SwiftData

@Model
public class Workout {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var startTime: Date
    public var endTime: Date?
    public var name: String
    public var typeString: String
    public var notes: String
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    public var exercises: [WorkoutExercise] = []
    
    public var type: WorkoutType {
        get { WorkoutType(rawValue: typeString) ?? .custom }
        set { typeString = newValue.rawValue }
    }
    
    public init(id: UUID = UUID(), date: Date = Date(), startTime: Date = Date(), endTime: Date? = nil, name: String = "Workout", type: WorkoutType = .custom, notes: String = "") {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.name = name
        self.typeString = type.rawValue
        self.notes = notes
    }
    
    // Computed statistics
    public var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
    
    public var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.totalVolume }
    }
    
    public var totalSets: Int {
        exercises.reduce(0) { $0 + $1.completedSetsCount }
    }
    
    public var totalReps: Int {
        exercises.reduce(0) { $0 + $1.totalReps }
    }
}

@Model
public class WorkoutExercise {
    @Attribute(.unique) public var id: UUID
    public var exerciseId: UUID?
    public var exerciseName: String
    public var muscleGroupString: String
    public var trackingTypeString: String
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    public var sets: [WorkoutSet] = []
    
    public var notes: String
    public var orderIndex: Int
    
    public var workout: Workout?
    
    public var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupString) ?? .chest }
        set { muscleGroupString = newValue.rawValue }
    }
    
    public var trackingType: TrackingType {
        get { TrackingType(rawValue: trackingTypeString) ?? .weightReps }
        set { trackingTypeString = newValue.rawValue }
    }
    
    public init(id: UUID = UUID(), exerciseId: UUID? = nil, exerciseName: String = "", muscleGroup: MuscleGroup = .chest, trackingType: TrackingType = .weightReps, notes: String = "", orderIndex: Int = 0) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.muscleGroupString = muscleGroup.rawValue
        self.trackingTypeString = trackingType.rawValue
        self.notes = notes
        self.orderIndex = orderIndex
    }
    
    public var totalVolume: Double {
        sets.filter { $0.isCompleted && !$0.isWarmup }.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    public var completedSetsCount: Int {
        sets.filter { $0.isCompleted }.count
    }
    
    public var totalReps: Int {
        sets.filter { $0.isCompleted }.reduce(0) { $0 + $1.reps }
    }
}

@Model
public class WorkoutSet {
    @Attribute(.unique) public var id: UUID
    public var setNumber: Int
    public var weight: Double
    public var reps: Int
    public var durationSeconds: TimeInterval
    public var distance: Double
    public var rpeValue: Int?
    public var isWarmup: Bool
    public var isCompleted: Bool
    public var notes: String
    
    public var workoutExercise: WorkoutExercise?
    
    public init(id: UUID = UUID(), setNumber: Int = 1, weight: Double = 0, reps: Int = 0, durationSeconds: TimeInterval = 0, distance: Double = 0, rpe: Int? = nil, isWarmup: Bool = false, isCompleted: Bool = false, notes: String = "") {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.distance = distance
        self.rpeValue = rpe
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.notes = notes
    }
}
