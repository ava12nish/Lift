import Foundation

@MainActor
public class WorkoutSuggestionService {
    public static let shared = WorkoutSuggestionService()
    
    private init() {}
    
    /// Finds the last workout where this exercise was performed
    public func lastWorkout(for exerciseName: String, in workouts: [Workout]) -> Workout? {
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        return sortedWorkouts.first { workout in
            workout.exercises.contains { $0.exerciseName == exerciseName }
        }
    }
    
    /// Finds the sets performed the last time this exercise was done
    public func lastSets(for exerciseName: String, in workouts: [Workout]) -> [WorkoutSet] {
        guard let workout = lastWorkout(for: exerciseName, in: workouts) else { return [] }
        guard let exercise = workout.exercises.first(where: { $0.exerciseName == exerciseName }) else { return [] }
        return exercise.sets.sorted { $0.setNumber < $1.setNumber }
    }
    
    /// Finds the best set (heaviest weight, or most reps at heaviest weight) for an exercise
    public func bestSet(for exerciseName: String, in workouts: [Workout]) -> WorkoutSet? {
        var allSets: [WorkoutSet] = []
        for w in workouts {
            for e in w.exercises where e.exerciseName == exerciseName {
                allSets.append(contentsOf: e.sets.filter { $0.isCompleted })
            }
        }
        return allSets.max { s1, s2 in
            if s1.weight != s2.weight {
                return s1.weight < s2.weight
            }
            return s1.reps < s2.reps
        }
    }
    
    /// Suggests target weight and reps based on previous performance
    public func suggestedToday(for exerciseName: String, in workouts: [Workout]) -> (weight: Double, reps: Int) {
        let sets = lastSets(for: exerciseName, in: workouts).filter { !$0.isWarmup }
        guard let firstSet = sets.first else {
            return (0, 0)
        }
        return (firstSet.weight, firstSet.reps)
    }
    
    /// Calculates the estimated 1RM using Epley's formula: weight * (1 + reps / 30)
    public func calculateEstimated1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }
}
