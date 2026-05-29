import SwiftUI
import SwiftData

public struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (Exercise) -> Void
    
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var showingCreateCustomSheet = false
    
    // Custom Exercise Form States
    @State private var customName = ""
    @State private var customMuscle = MuscleGroup.chest
    @State private var customEquipment = EquipmentType.barbell
    @State private var customTracking = TrackingType.weightReps
    
    public init(onSelect: @escaping (Exercise) -> Void) {
        self.onSelect = onSelect
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search exercises...", text: $searchText)
                            .foregroundColor(.primary)
                            .tint(.green)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Muscle Group Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button(action: {
                                selectedMuscleGroup = nil
                                HapticsService.shared.triggerImpact(style: .light)
                            }) {
                                Text("All")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(selectedMuscleGroup == nil ? Color(.systemBackground) : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedMuscleGroup == nil ? Color.green : Color(.tertiarySystemBackground))
                                    .cornerRadius(10)
                            }
                            
                            ForEach(MuscleGroup.allCases) { group in
                                Button(action: {
                                    selectedMuscleGroup = group
                                    HapticsService.shared.triggerImpact(style: .light)
                                }) {
                                    Text(group.rawValue)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(selectedMuscleGroup == group ? Color(.systemBackground) : .primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedMuscleGroup == group ? Color.green : Color(.tertiarySystemBackground))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Exercise List
                    List {
                        let filtered = filteredExercises
                        if filtered.isEmpty {
                            Text("No exercises match your search")
                                .foregroundColor(.gray)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(filtered) { exercise in
                                Button(action: {
                                    onSelect(exercise)
                                    dismiss()
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.primary)
                                            
                                            Text("\(exercise.muscleGroup.rawValue) • \(exercise.equipment.rawValue)")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        
                                        if exercise.isCustom {
                                            Text("Custom")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.green.opacity(0.12))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                .listRowBackground(Color(.secondarySystemBackground))
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    
                    // Create Custom Button
                    Button(action: {
                        showingCreateCustomSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Custom Exercise")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(12)
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
            .sheet(isPresented: $showingCreateCustomSheet) {
                createCustomSheet
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredExercises: [Exercise] {
        allExercises.filter { ex in
            let matchesSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscleGroup == nil || ex.muscleGroup == selectedMuscleGroup
            return matchesSearch && matchesMuscle
        }
    }
    
    // MARK: - Custom Sheet
    private var createCustomSheet: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                Form {
                    Section("Details") {
                        TextField("Exercise Name (e.g. Hammer Strength Incline)", text: $customName)
                            .foregroundColor(.primary)
                            .listRowBackground(Color(.secondarySystemBackground))
                        
                        Picker("Muscle Group", selection: $customMuscle) {
                            ForEach(MuscleGroup.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .foregroundColor(.primary)
                        .listRowBackground(Color(.secondarySystemBackground))
                        
                        Picker("Equipment", selection: $customEquipment) {
                            ForEach(EquipmentType.allCases) { eq in
                                Text(eq.rawValue).tag(eq)
                            }
                        }
                        .foregroundColor(.primary)
                        .listRowBackground(Color(.secondarySystemBackground))
                        
                        Picker("Tracking Type", selection: $customTracking) {
                            ForEach(TrackingType.allCases) { track in
                                Text(track.rawValue).tag(track)
                            }
                        }
                        .foregroundColor(.primary)
                        .listRowBackground(Color(.secondarySystemBackground))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCreateCustomSheet = false
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createCustom()
                    }
                    .foregroundColor(customName.isEmpty ? .gray : .green)
                    .disabled(customName.isEmpty)
                }
            }
        }
    }
    
    private func createCustom() {
        let exercise = Exercise(
            name: customName,
            muscleGroup: customMuscle,
            equipment: customEquipment,
            trackingType: customTracking,
            isCustom: true
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        
        customName = ""
        showingCreateCustomSheet = false
        HapticsService.shared.triggerNotification(type: .success)
    }
}
