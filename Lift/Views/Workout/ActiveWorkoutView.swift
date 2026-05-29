import SwiftUI
import SwiftData

public struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessionManager = WorkoutSessionManager.shared
    @State private var showingAddExerciseSheet = false
    @State private var showingCancelAlert = false
    
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let workout = sessionManager.activeWorkout {
                    VStack(spacing: 0) {
                        // Title & Timing Header
                        headerSection(workout: workout)
                        
                        // Exercises List
                        ScrollView {
                            VStack(spacing: 20) {
                                // Workout general notes
                                TextField("Tap to add workout notes...", text: Bindable(workout).notes)
                                    .font(.system(size: 13))
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color(white: 0.08))
                                    .cornerRadius(12)
                                    .padding(.top, 10)
                                
                                if workout.exercises.isEmpty {
                                    emptyExercisesState
                                } else {
                                    exercisesList(workout: workout)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 120) // spacing for floating rest timer & bottom bar
                        }
                        
                        // Rest Timer Banner (Floating)
                        RestTimerView()
                            .padding(.bottom, 8)
                        
                        // Bottom Controls
                        bottomActionBar(workout: workout)
                    }
                } else {
                    VStack {
                        Text("No active workout session.")
                            .foregroundColor(.gray)
                        Button("Close") {
                            dismiss()
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive, action: {
                        showingCancelAlert = true
                    }) {
                        Text("Cancel")
                            .foregroundColor(.red)
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: finishWorkout) {
                        Text("Finish")
                            .foregroundColor(.green)
                            .font(.system(size: 15, weight: .bold))
                    }
                }
            }
            .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
                Button("Discard Workout", role: .destructive) {
                    sessionManager.cancelActiveWorkout(context: modelContext)
                    dismiss()
                }
                Button("Keep Lifting", role: .cancel) {}
            } message: {
                Text("Are you sure you want to discard this workout? All logged sets will be permanently deleted.")
            }
            .sheet(isPresented: $showingAddExerciseSheet) {
                AddExerciseView { exercise in
                    sessionManager.addExerciseToActiveWorkout(exercise, context: modelContext, history: allWorkouts)
                }
            }
        }
    }
    
    // MARK: - Header
    private func headerSection(workout: Workout) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                // Workout Title
                TextField("Workout Name", text: Bindable(workout).name)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tint(.green)
                
                Spacer()
                
                // Duration Timer
                TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(workout.startTime)
                    Text(formatDuration(elapsed))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            // Category Selector Tab
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WorkoutType.allCases) { type in
                        Button(action: {
                            workout.type = type
                            HapticsService.shared.triggerImpact(style: .light)
                        }) {
                            Text(type.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(workout.type == type ? .black : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(workout.type == type ? Color.green : Color(white: 0.12))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
                .background(Color.white.opacity(0.12))
        }
        .padding(.top, 10)
    }
    
    // MARK: - Empty Exercises State
    private var emptyExercisesState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 44))
                .foregroundColor(.gray)
            Text("Empty Workout Session")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text("Tap the button below to add exercises to this workout.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Exercises List
    private func exercisesList(workout: Workout) -> some View {
        // Sort exercises by orderIndex
        let sortedExercises = workout.exercises.sorted { $0.orderIndex < $1.orderIndex }
        
        return ForEach(sortedExercises) { exercise in
            VStack(alignment: .leading, spacing: 12) {
                // Exercise Name Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.exerciseName)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(exercise.muscleGroup.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Quick Menu
                    Menu {
                        Button(role: .destructive, action: {
                            deleteExercise(exercise, in: workout)
                        }) {
                            Label("Remove Lift", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                
                // Exercise Notes
                TextField("Add note for this exercise...", text: Bindable(exercise).notes)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 4)
                
                // Smart Suggestions
                if let suggestion = getSuggestion(for: exercise.exerciseName) {
                    Text(suggestion)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.vertical, 2)
                }
                
                // Sets Headers
                HStack(spacing: 8) {
                    Text("SET").frame(width: 32, alignment: .leading)
                    Text("TYPE").frame(width: 50, alignment: .center)
                    Text("PREV").frame(width: 70, alignment: .leading)
                    Text("LBS").frame(width: 60, alignment: .center)
                    Text("REPS").frame(width: 50, alignment: .center)
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 35, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
                
                // Set Rows
                let sortedSets = exercise.sets.sorted { $0.setNumber < $1.setNumber }
                ForEach(sortedSets) { set in
                    let prevText = getPreviousSetText(exerciseName: exercise.exerciseName, index: set.setNumber - 1)
                    
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            // Set Number
                            Text("\(set.setNumber)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(width: 32, alignment: .leading)
                            
                            // Set Type Button
                            Button(action: {
                                set.isWarmup.toggle()
                                HapticsService.shared.triggerImpact(style: .light)
                            }) {
                                Text(set.isWarmup ? "WARM" : "WORK")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(set.isWarmup ? .orange : .green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background((set.isWarmup ? Color.orange : Color.green).opacity(0.12))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 50, alignment: .center)
                            
                            // Prev stats
                            Text(prevText)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                                .frame(width: 70, alignment: .leading)
                                .lineLimit(1)
                            
                            // Weight Input
                            TextField("0", value: Bindable(set).weight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .padding(6)
                                .background(Color(white: 0.15))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .frame(width: 60, alignment: .center)
                            
                            // Reps Input
                            TextField("0", value: Bindable(set).reps, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .padding(6)
                                .background(Color(white: 0.15))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .frame(width: 50, alignment: .center)
                            
                            Spacer()
                            
                            // Completed Button
                            Button(action: {
                                toggleSetCompleted(set, in: exercise)
                            }) {
                                Image(systemName: set.isCompleted ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 22))
                                    .foregroundColor(set.isCompleted ? .green : .gray)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 35, alignment: .trailing)
                        }
                        
                        // Inline increment/decrement buttons if focused
                        HStack(spacing: 8) {
                            Spacer()
                            
                            // Weight increment
                            Button("-5 lb") { incrementWeight(set, by: -5) }
                            Button("+5 lb") { incrementWeight(set, by: 5) }
                            
                            Spacer().frame(width: 10)
                            
                            // Reps increment
                            Button("-1 rep") { incrementReps(set, by: -1) }
                            Button("+1 rep") { incrementReps(set, by: 1) }
                            
                            Spacer()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.vertical, 2)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteSet(set, in: exercise)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                // Add Set Button
                Button(action: {
                    addSet(to: exercise)
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Set")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(white: 0.08))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Bottom Actions Bar
    private func bottomActionBar(workout: Workout) -> some View {
        HStack(spacing: 16) {
            Button(action: {
                showingAddExerciseSheet = true
                HapticsService.shared.triggerImpact(style: .light)
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Exercise")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(white: 0.12))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            
            Button(action: finishWorkout) {
                Text("Finish Workout")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.95))
    }
    
    // MARK: - Actions & Helpers
    private func addSet(to exercise: WorkoutExercise) {
        let lastSet = exercise.sets.sorted(by: { $0.setNumber < $1.setNumber }).last
        let newSetNumber = (lastSet?.setNumber ?? 0) + 1
        
        let newSet = WorkoutSet(
            setNumber: newSetNumber,
            weight: lastSet?.weight ?? 0,
            reps: lastSet?.reps ?? 0,
            isWarmup: false,
            isCompleted: false
        )
        exercise.sets.append(newSet)
        modelContext.insert(newSet)
        HapticsService.shared.triggerImpact(style: .light)
    }
    
    private func deleteSet(_ set: WorkoutSet, in exercise: WorkoutExercise) {
        modelContext.delete(set)
        exercise.sets.removeAll { $0.id == set.id }
        
        // Re-number remaining sets
        let sorted = exercise.sets.sorted { $0.setNumber < $1.setNumber }
        for (index, item) in sorted.enumerated() {
            item.setNumber = index + 1
        }
        
        HapticsService.shared.triggerImpact(style: .medium)
    }
    
    private func deleteExercise(_ exercise: WorkoutExercise, in workout: Workout) {
        modelContext.delete(exercise)
        workout.exercises.removeAll { $0.id == exercise.id }
        
        // Re-number indices
        let sorted = workout.exercises.sorted { $0.orderIndex < $1.orderIndex }
        for (index, item) in sorted.enumerated() {
            item.orderIndex = index
        }
        
        HapticsService.shared.triggerImpact(style: .medium)
    }
    
    private func toggleSetCompleted(_ set: WorkoutSet, in exercise: WorkoutExercise) {
        set.isCompleted.toggle()
        
        if set.isCompleted {
            HapticsService.shared.triggerNotification(type: .success)
            
            // Start the rest timer
            let restSeconds = UserSettingsManager.shared.defaultRestSeconds
            RestTimerManager.shared.start(duration: restSeconds)
        } else {
            HapticsService.shared.triggerImpact(style: .light)
        }
        
        try? modelContext.save()
    }
    
    private func incrementWeight(_ set: WorkoutSet, by value: Double) {
        set.weight = max(0, set.weight + value)
        HapticsService.shared.triggerImpact(style: .light)
    }
    
    private func incrementReps(_ set: WorkoutSet, by value: Int) {
        set.reps = max(0, set.reps + value)
        HapticsService.shared.triggerImpact(style: .light)
    }
    
    private func finishWorkout() {
        sessionManager.finishActiveWorkout(allWorkouts: allWorkouts, context: modelContext)
        dismiss()
    }
    
    // Suggestion logic
    private func getSuggestion(for exerciseName: String) -> String? {
        let target = WorkoutSuggestionService.shared.suggestedToday(for: exerciseName, in: allWorkouts)
        if target.weight > 0 && target.reps > 0 {
            return "Suggested: \(Int(target.weight)) \(UserSettingsManager.shared.weightUnit.rawValue) x \(target.reps) (from last workout)"
        }
        return nil
    }
    
    private func getPreviousSetText(exerciseName: String, index: Int) -> String {
        let lastSets = WorkoutSuggestionService.shared.lastSets(for: exerciseName, in: allWorkouts)
        guard index < lastSets.count else { return "—" }
        let prevSet = lastSets[index]
        return "\(Int(prevSet.weight))x\(prevSet.reps)"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
