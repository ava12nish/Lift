import SwiftUI
import SwiftData

public struct CreateTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Editing Mode State
    private var editingTemplate: WorkoutTemplate?
    
    @State private var templateName: String = ""
    @State private var workoutType: WorkoutType = .custom
    @State private var exercisesList: [LocalTemplateExercise] = []
    
    @State private var showingAddExerciseSheet = false
    
    public init(editingTemplate: WorkoutTemplate? = nil) {
        self.editingTemplate = editingTemplate
        _templateName = State(initialValue: editingTemplate?.name ?? "")
        _workoutType = State(initialValue: editingTemplate?.type ?? .custom)
        
        if let template = editingTemplate {
            let sortedEx = template.exercises.sorted { $0.orderIndex < $1.orderIndex }
            let locals = sortedEx.map { ex -> LocalTemplateExercise in
                let sortedSets = ex.sets.sorted { $0.setNumber < $1.setNumber }
                let localSets = sortedSets.map { s in
                    LocalTemplateSet(weight: s.weight, reps: s.reps, isWarmup: s.isWarmup)
                }
                return LocalTemplateExercise(name: ex.exerciseName, muscleGroup: ex.muscleGroup, trackingType: ex.trackingType, sets: localSets)
            }
            _exercisesList = State(initialValue: locals)
        }
    }
    
    // Local Structs for simpler state manipulation
    struct LocalTemplateExercise: Identifiable {
        let id = UUID()
        var name: String
        var muscleGroup: MuscleGroup
        var trackingType: TrackingType
        var sets: [LocalTemplateSet]
    }
    
    struct LocalTemplateSet: Identifiable {
        let id = UUID()
        var weight: Double
        var reps: Int
        var isWarmup: Bool
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Form {
                        Section("Template Info") {
                            TextField("Template Name (e.g. Chest & Shoulders)", text: $templateName)
                                .foregroundColor(.white)
                                .listRowBackground(Color(white: 0.1))
                            
                            Picker("Workout Category", selection: $workoutType) {
                                ForEach(WorkoutType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.1))
                        }
                        
                        Section("Exercises") {
                            if exercisesList.isEmpty {
                                Text("Add exercises to this template below")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .listRowBackground(Color(white: 0.1))
                            } else {
                                ForEach($exercisesList) { $ex in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text(ex.name)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                removeExercise(ex.id)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        
                                        // Sets Header
                                        HStack {
                                            Text("Set").frame(width: 35, alignment: .leading)
                                            Text("Type").frame(width: 60, alignment: .center)
                                            Text("Weight").frame(width: 80, alignment: .center)
                                            Text("Reps").frame(width: 60, alignment: .center)
                                            Spacer()
                                        }
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.gray)
                                        
                                        // Sets Fields
                                        ForEach(Array(ex.sets.enumerated()), id: \.element.id) { index, _ in
                                            HStack {
                                                // Set #
                                                Text("\(index + 1)")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(width: 35, alignment: .leading)
                                                
                                                // Set Type
                                                Button(action: {
                                                    ex.sets[index].isWarmup.toggle()
                                                    HapticsService.shared.triggerImpact(style: .light)
                                                }) {
                                                    Text(ex.sets[index].isWarmup ? "WARM" : "WORK")
                                                        .font(.system(size: 9, weight: .black))
                                                        .foregroundColor(ex.sets[index].isWarmup ? .orange : .green)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 4)
                                                        .background((ex.sets[index].isWarmup ? Color.orange : Color.green).opacity(0.12))
                                                        .cornerRadius(4)
                                                }
                                                .buttonStyle(.plain)
                                                .frame(width: 60, alignment: .center)
                                                
                                                // Weight Input
                                                HStack(spacing: 2) {
                                                    TextField("0", value: $ex.sets[index].weight, format: .number)
                                                        .keyboardType(.decimalPad)
                                                        .multilineTextAlignment(.center)
                                                        .padding(6)
                                                        .background(Color(white: 0.18))
                                                        .cornerRadius(8)
                                                        .foregroundColor(.white)
                                                    
                                                    Text(UserSettingsManager.shared.weightUnit.rawValue)
                                                        .font(.system(size: 10))
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(width: 80, alignment: .center)
                                                
                                                // Reps Input
                                                TextField("0", value: $ex.sets[index].reps, format: .number)
                                                    .keyboardType(.numberPad)
                                                    .multilineTextAlignment(.center)
                                                    .padding(6)
                                                    .background(Color(white: 0.18))
                                                    .cornerRadius(8)
                                                    .foregroundColor(.white)
                                                    .frame(width: 60, alignment: .center)
                                                
                                                Spacer()
                                                
                                                // Delete set
                                                Button(action: {
                                                    ex.sets.remove(at: index)
                                                    HapticsService.shared.triggerImpact(style: .light)
                                                }) {
                                                    Image(systemName: "trash")
                                                        .foregroundColor(.red)
                                                        .font(.system(size: 12))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        
                                        // Add set button
                                        Button(action: {
                                            addSetToExercise(ex.id)
                                        }) {
                                            HStack {
                                                Image(systemName: "plus")
                                                Text("Add Set")
                                            }
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.green)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 8)
                                    .listRowBackground(Color(white: 0.1))
                                }
                                .onMove(perform: moveExercise)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                    
                    // Bottom Add Exercise Trigger
                    Button(action: {
                        showingAddExerciseSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Exercise")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(12)
                        .padding()
                    }
                }
            }
            .navigationTitle(editingTemplate != nil ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .foregroundColor(templateName.isEmpty ? .gray : .green)
                    .disabled(templateName.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddExerciseSheet) {
                AddExerciseView { selectedExercise in
                    addExercise(selectedExercise)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func addExercise(_ exercise: Exercise) {
        let newEx = LocalTemplateExercise(
            name: exercise.name,
            muscleGroup: exercise.muscleGroup,
            trackingType: exercise.trackingType,
            sets: [LocalTemplateSet(weight: 0, reps: 0, isWarmup: false)]
        )
        exercisesList.append(newEx)
        HapticsService.shared.triggerImpact(style: .light)
    }
    
    private func removeExercise(_ id: UUID) {
        exercisesList.removeAll { $0.id == id }
        HapticsService.shared.triggerImpact(style: .medium)
    }
    
    private func addSetToExercise(_ exID: UUID) {
        if let index = exercisesList.firstIndex(where: { $0.id == exID }) {
            let lastSet = exercisesList[index].sets.last
            let newSet = LocalTemplateSet(
                weight: lastSet?.weight ?? 0,
                reps: lastSet?.reps ?? 0,
                isWarmup: false
            )
            exercisesList[index].sets.append(newSet)
            HapticsService.shared.triggerImpact(style: .light)
        }
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        exercisesList.move(fromOffsets: source, toOffset: destination)
    }
    
    private func saveTemplate() {
        if let editing = editingTemplate {
            // Edit existing
            editing.name = templateName
            editing.type = workoutType
            
            // Delete old exercises
            for ex in editing.exercises {
                modelContext.delete(ex)
            }
            editing.exercises.removeAll()
            
            // Re-insert
            for (i, localEx) in exercisesList.enumerated() {
                let tempEx = TemplateExercise(
                    exerciseName: localEx.name,
                    muscleGroup: localEx.muscleGroup,
                    trackingType: localEx.trackingType,
                    orderIndex: i
                )
                editing.exercises.append(tempEx)
                modelContext.insert(tempEx)
                
                for (j, localSet) in localEx.sets.enumerated() {
                    let tempSet = TemplateSet(
                        setNumber: j + 1,
                        weight: localSet.weight,
                        reps: localSet.reps,
                        isWarmup: localSet.isWarmup
                    )
                    tempEx.sets.append(tempSet)
                    modelContext.insert(tempSet)
                }
            }
        } else {
            // Create new template
            let newTemplate = WorkoutTemplate(name: templateName, type: workoutType)
            modelContext.insert(newTemplate)
            
            for (i, localEx) in exercisesList.enumerated() {
                let tempEx = TemplateExercise(
                    exerciseName: localEx.name,
                    muscleGroup: localEx.muscleGroup,
                    trackingType: localEx.trackingType,
                    orderIndex: i
                )
                newTemplate.exercises.append(tempEx)
                modelContext.insert(tempEx)
                
                for (j, localSet) in localEx.sets.enumerated() {
                    let tempSet = TemplateSet(
                        setNumber: j + 1,
                        weight: localSet.weight,
                        reps: localSet.reps,
                        isWarmup: localSet.isWarmup
                    )
                    tempEx.sets.append(tempSet)
                    modelContext.insert(tempSet)
                }
            }
        }
        
        try? modelContext.save()
        HapticsService.shared.triggerNotification(type: .success)
        dismiss()
    }
}
