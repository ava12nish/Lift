import Foundation
import SwiftData

@MainActor
public class PRService {
    public static let shared = PRService()
    
    private init() {}
    
    /// Scans a completed workout against history to identify any new Personal Records
    /// Returns the array of new PRs that were unlocked
    public func checkForPRs(completedWorkout: Workout, allWorkouts: [Workout], context: ModelContext) -> [PersonalRecord] {
        var newPRs: [PersonalRecord] = []
        
        // Exclude the completed workout itself from historical comparison
        let history = allWorkouts.filter { $0.id != completedWorkout.id }
        
        // 1. Longest workout check
        let completedDuration = completedWorkout.duration
        let maxPastDuration = history.map { $0.duration }.max() ?? 0
        if completedDuration > maxPastDuration && completedDuration > 0 && !history.isEmpty {
            let pr = PersonalRecord(
                exerciseName: "Workout Duration",
                typeString: "duration",
                value: completedDuration,
                weight: 0,
                reps: 0,
                estimatedOneRepMax: 0,
                date: completedWorkout.date,
                workoutId: completedWorkout.id
            )
            newPRs.append(pr)
            context.insert(pr)
        }
        
        // 2. Highest total workout volume in one day check
        let completedVolume = completedWorkout.totalVolume
        let maxPastVolume = history.map { $0.totalVolume }.max() ?? 0
        if completedVolume > maxPastVolume && completedVolume > 0 && !history.isEmpty {
            let pr = PersonalRecord(
                exerciseName: "Daily Volume",
                typeString: "dailyVolume",
                value: completedVolume,
                weight: 0,
                reps: 0,
                estimatedOneRepMax: 0,
                date: completedWorkout.date,
                workoutId: completedWorkout.id
            )
            newPRs.append(pr)
            context.insert(pr)
        }
        
        // 3. Exercise-level PRs
        for we in completedWorkout.exercises {
            let name = we.exerciseName
            let completedSets = we.sets.filter { $0.isCompleted }
            guard !completedSets.isEmpty else { continue }
            
            // Collect historical sets for this exercise
            var historicalSets: [WorkoutSet] = []
            var historicalExerciseVolumes: [Double] = []
            
            for pastWorkout in history {
                for pastEx in pastWorkout.exercises where pastEx.exerciseName == name {
                    historicalSets.append(contentsOf: pastEx.sets.filter { $0.isCompleted })
                    historicalExerciseVolumes.append(pastEx.totalVolume)
                }
            }
            
            // A. Heaviest weight
            let completedMaxWeight = completedSets.map { $0.weight }.max() ?? 0
            let historicalMaxWeight = historicalSets.map { $0.weight }.max() ?? 0
            if completedMaxWeight > historicalMaxWeight && completedMaxWeight > 0 {
                let pr = PersonalRecord(
                    exerciseName: name,
                    typeString: "weight",
                    value: completedMaxWeight,
                    weight: completedMaxWeight,
                    reps: completedSets.first(where: { $0.weight == completedMaxWeight })?.reps ?? 0,
                    estimatedOneRepMax: 0,
                    date: completedWorkout.date,
                    workoutId: completedWorkout.id
                )
                newPRs.append(pr)
                context.insert(pr)
            }
            
            // B. Best 1RM
            let completedMax1RM = completedSets.map {
                WorkoutSuggestionService.shared.calculateEstimated1RM(weight: $0.weight, reps: $0.reps)
            }.max() ?? 0
            
            let historicalMax1RM = historicalSets.map {
                WorkoutSuggestionService.shared.calculateEstimated1RM(weight: $0.weight, reps: $0.reps)
            }.max() ?? 0
            
            if completedMax1RM > historicalMax1RM && completedMax1RM > 0 {
                let bestSet = completedSets.max(by: {
                    WorkoutSuggestionService.shared.calculateEstimated1RM(weight: $0.weight, reps: $0.reps) <
                    WorkoutSuggestionService.shared.calculateEstimated1RM(weight: $1.weight, reps: $1.reps)
                })
                
                if let bestSet = bestSet {
                    let pr = PersonalRecord(
                        exerciseName: name,
                        typeString: "oneRepMax",
                        value: completedMax1RM,
                        weight: bestSet.weight,
                        reps: bestSet.reps,
                        estimatedOneRepMax: completedMax1RM,
                        date: completedWorkout.date,
                        workoutId: completedWorkout.id
                    )
                    newPRs.append(pr)
                    context.insert(pr)
                }
            }
            
            // C. Highest total volume for this exercise
            let completedExVolume = we.totalVolume
            let historicalMaxExVolume = historicalExerciseVolumes.max() ?? 0
            if completedExVolume > historicalMaxExVolume && completedExVolume > 0 && !historicalExerciseVolumes.isEmpty {
                let pr = PersonalRecord(
                    exerciseName: name,
                    typeString: "exerciseVolume",
                    value: completedExVolume,
                    weight: 0,
                    reps: 0,
                    estimatedOneRepMax: 0,
                    date: completedWorkout.date,
                    workoutId: completedWorkout.id
                )
                newPRs.append(pr)
                context.insert(pr)
            }
            
            // D. Most reps at a given weight
            for completedSet in completedSets where completedSet.weight > 0 {
                let w = completedSet.weight
                let reps = completedSet.reps
                
                let historicalMaxRepsAtWeight = historicalSets
                    .filter { $0.weight == w }
                    .map { $0.reps }
                    .max() ?? 0
                
                if reps > historicalMaxRepsAtWeight && reps > 0 {
                    // Check if we haven't already registered a PR for this exact weight in this exercise in this run
                    if !newPRs.contains(where: { $0.exerciseName == name && $0.typeString == "reps" && $0.weight == w }) {
                        let pr = PersonalRecord(
                            exerciseName: name,
                            typeString: "reps",
                            value: Double(reps),
                            weight: w,
                            reps: reps,
                            estimatedOneRepMax: 0,
                            date: completedWorkout.date,
                            workoutId: completedWorkout.id
                        )
                        newPRs.append(pr)
                        context.insert(pr)
                    }
                }
            }
        }
        
        // Save database context updates
        try? context.save()
        
        return newPRs
    }
}
