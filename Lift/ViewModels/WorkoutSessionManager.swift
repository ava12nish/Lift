import SwiftUI
import SwiftData

@MainActor
@Observable
public class WorkoutSessionManager {
    public static let shared = WorkoutSessionManager()
    
    public var activeWorkout: Workout?
    public var recentFinishedWorkout: Workout?
    public var showPRCelebration: Bool = false
    public var lastUnlockedPRs: [PersonalRecord] = []
    
    private init() {}
    
    public func startNewWorkout(name: String = "Workout", type: WorkoutType = .custom, context: ModelContext) {
        let workout = Workout(
            date: Date(),
            startTime: Date(),
            name: name,
            type: type
        )
        context.insert(workout)
        activeWorkout = workout
        HapticsService.shared.triggerImpact(style: .medium)
    }
    
    public func startWorkoutFromTemplate(_ template: WorkoutTemplate, context: ModelContext) {
        let workout = Workout(
            date: Date(),
            startTime: Date(),
            name: template.name,
            type: template.type
        )
        context.insert(workout)
        
        // Copy exercises and sets from template
        for (index, tempEx) in template.exercises.enumerated() {
            let workoutEx = WorkoutExercise(
                exerciseName: tempEx.exerciseName,
                muscleGroup: tempEx.muscleGroup,
                trackingType: tempEx.trackingType,
                orderIndex: index
            )
            workout.exercises.append(workoutEx)
            context.insert(workoutEx)
            
            for tempSet in tempEx.sets {
                let workoutSet = WorkoutSet(
                    setNumber: tempSet.setNumber,
                    weight: tempSet.weight,
                    reps: tempSet.reps,
                    durationSeconds: tempSet.durationSeconds,
                    distance: tempSet.distance,
                    isWarmup: tempSet.isWarmup,
                    isCompleted: false // User must complete them during the workout
                )
                workoutEx.sets.append(workoutSet)
                context.insert(workoutSet)
            }
        }
        
        activeWorkout = workout
        HapticsService.shared.triggerImpact(style: .medium)
    }
    
    public func addExerciseToActiveWorkout(_ exercise: Exercise, context: ModelContext, history: [Workout]) {
        guard let workout = activeWorkout else { return }
        
        let order = workout.exercises.count
        let workoutEx = WorkoutExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            muscleGroup: exercise.muscleGroup,
            trackingType: exercise.trackingType,
            orderIndex: order
        )
        
        // Pre-fill sets based on smart defaults!
        let lastSets = WorkoutSuggestionService.shared.lastSets(for: exercise.name, in: history)
        if !lastSets.isEmpty {
            for (i, lastSet) in lastSets.enumerated() {
                let newSet = WorkoutSet(
                    setNumber: i + 1,
                    weight: lastSet.weight,
                    reps: lastSet.reps,
                    durationSeconds: lastSet.durationSeconds,
                    distance: lastSet.distance,
                    isWarmup: lastSet.isWarmup,
                    isCompleted: false
                )
                workoutEx.sets.append(newSet)
                context.insert(newSet)
            }
        } else {
            // Default first set
            let defaultSet = WorkoutSet(setNumber: 1, weight: 0, reps: 0, isCompleted: false)
            workoutEx.sets.append(defaultSet)
            context.insert(defaultSet)
        }
        
        workout.exercises.append(workoutEx)
        context.insert(workoutEx)
        HapticsService.shared.triggerImpact(style: .light)
    }
    
    public func finishActiveWorkout(allWorkouts: [Workout], context: ModelContext) {
        guard let workout = activeWorkout else { return }
        workout.endTime = Date()
        
        // Filter out uncompleted sets and empty exercises
        for exercise in workout.exercises {
            exercise.sets = exercise.sets.filter { $0.isCompleted }
            // Sort sets by setNumber
            exercise.sets.sort { $0.setNumber < $1.setNumber }
        }
        workout.exercises = workout.exercises.filter { !$0.sets.isEmpty }
        
        // Check for PRs
        let unlockedPRs = PRService.shared.checkForPRs(completedWorkout: workout, allWorkouts: allWorkouts, context: context)
        
        recentFinishedWorkout = workout
        activeWorkout = nil
        
        if !unlockedPRs.isEmpty {
            lastUnlockedPRs = unlockedPRs
            showPRCelebration = true
            SoundService.shared.playSuccessAlert()
        } else {
            HapticsService.shared.triggerNotification(type: .success)
        }
        
        try? context.save()
    }
    
    public func cancelActiveWorkout(context: ModelContext) {
        guard let workout = activeWorkout else { return }
        context.delete(workout)
        activeWorkout = nil
        try? context.save()
        HapticsService.shared.triggerImpact(style: .heavy)
    }
}
