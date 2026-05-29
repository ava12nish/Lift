import SwiftUI
import SwiftData

public struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var workout: Workout
    
    @Query(sort: \BodyweightEntry.date, order: .reverse) private var bodyweightEntries: [BodyweightEntry]
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    
    @State private var isEditing = false
    @State private var showingShareSheet = false
    
    public init(workout: Workout) {
        self.workout = workout
    }
    
    public var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Stats
                    headerSection
                    
                    // Workout general notes
                    notesSection
                    
                    // Exercises List
                    exercisesSection
                    
                    // Actions Bar (Log Again / Delete)
                    actionsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 60)
            }
        }
        .navigationTitle(isEditing ? "Edit Session" : "Workout Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if isEditing {
                        Button("Done") {
                            isEditing = false
                            try? modelContext.save()
                            HapticsService.shared.triggerNotification(type: .success)
                        }
                        .foregroundColor(.green)
                        .font(.system(size: 15, weight: .bold))
                    } else {
                        Button(action: {
                            showingShareSheet = true
                            HapticsService.shared.triggerImpact(style: .light)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                        }
                        
                        Button("Edit") {
                            isEditing = true
                            HapticsService.shared.triggerImpact(style: .light)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareCardPreviewView(
                type: .workout,
                workout: workout,
                bodyweightEntries: bodyweightEntries,
                streakCount: 3 // Mock streak for presentation
            )
        }
    }
    
    // MARK: - Header Info
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if isEditing {
                    TextField("Workout Name", text: $workout.name)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                        .tint(.green)
                } else {
                    Text(workout.name)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: workout.type.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(.green)
            }
            
            Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
            
            Divider()
                .background(Color.primary.opacity(0.15))
                .padding(.vertical, 4)
            
            // Core Stats Grid
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DURATION")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text(formatDuration(workout.duration))
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("VOLUME")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(Int(workout.totalVolume)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL SETS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(workout.totalSets) Sets")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Notes
    private var notesSection: some View {
        Group {
            if isEditing {
                TextField("Edit workout notes...", text: $workout.notes)
                    .font(.system(size: 13))
                    .padding()
                    .foregroundColor(.primary)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
            } else if !workout.notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NOTES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    Text(workout.notes)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Exercises
    private var exercisesSection: some View {
        let sortedEx = workout.exercises.sorted { $0.orderIndex < $1.orderIndex }
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("EXERCISES COMPLETED")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1.5)
            
            ForEach(sortedEx) { ex in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(ex.exerciseName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(ex.muscleGroup.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(6)
                    }
                    
                    if !ex.notes.isEmpty {
                        Text(ex.notes)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .italic()
                    }
                    
                    // Table Rows
                    let sortedSets = ex.sets.sorted { $0.setNumber < $1.setNumber }
                    ForEach(sortedSets) { set in
                        HStack {
                            Text("Set \(set.setNumber)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.gray)
                                .frame(width: 50, alignment: .leading)
                            
                            if set.isWarmup {
                                Text("Warm-up")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12))
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(set.weight)) \(UserSettingsManager.shared.weightUnit.rawValue) x \(set.reps)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        .swipeActions {
                            if isEditing {
                                Button(role: .destructive) {
                                    deleteSet(set, in: ex)
                                } label: {
                                    Label("Delete Set", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Actions (Log Again / Delete)
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: duplicateAndLog) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Perform Workout Again")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.green)
                .cornerRadius(14)
            }
            
            Button(role: .destructive, action: deleteWorkout) {
                Text("Delete Workout Log")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(14)
            }
            .padding(.top, 10)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Actions
    private func deleteSet(_ set: WorkoutSet, in exercise: WorkoutExercise) {
        modelContext.delete(set)
        exercise.sets.removeAll { $0.id == set.id }
        
        let sorted = exercise.sets.sorted { $0.setNumber < $1.setNumber }
        for (i, item) in sorted.enumerated() {
            item.setNumber = i + 1
        }
        try? modelContext.save()
    }
    
    private func duplicateAndLog() {
        let newWorkout = Workout(
            date: Date(),
            startTime: Date(),
            name: workout.name,
            type: workout.type
        )
        modelContext.insert(newWorkout)
        
        for (i, ex) in workout.exercises.enumerated() {
            let newEx = WorkoutExercise(
                exerciseId: ex.exerciseId,
                exerciseName: ex.exerciseName,
                muscleGroup: ex.muscleGroup,
                trackingType: ex.trackingType,
                orderIndex: i
            )
            newWorkout.exercises.append(newEx)
            modelContext.insert(newEx)
            
            for set in ex.sets {
                let newSet = WorkoutSet(
                    setNumber: set.setNumber,
                    weight: set.weight,
                    reps: set.reps,
                    isWarmup: set.isWarmup,
                    isCompleted: false
                )
                newEx.sets.append(newSet)
                modelContext.insert(newSet)
            }
        }
        
        WorkoutSessionManager.shared.activeWorkout = newWorkout
        HapticsService.shared.triggerImpact(style: .medium)
        dismiss()
    }
    
    private func deleteWorkout() {
        modelContext.delete(workout)
        try? modelContext.save()
        HapticsService.shared.triggerImpact(style: .medium)
        dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
