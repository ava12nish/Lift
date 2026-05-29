import SwiftUI
import SwiftData

public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var settings = UserSettingsManager.shared
    @State private var showingResetAlert = false
    @State private var showingHealthSuccessAlert = false
    @State private var showingHealthErrorAlert = false
    @State private var healthErrorMessage = ""
    @State private var showingExportSheet = false
    @State private var exportText = ""
    
    @Query private var workouts: [Workout]
    @Query private var bodyweight: [BodyweightEntry]
    @Query private var exercises: [Exercise]
    @Query private var templates: [WorkoutTemplate]
    @Query private var prs: [PersonalRecord]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Form {
                    Section("Workout Preferences") {
                        Picker("Weight Unit", selection: Bindable(settings).weightUnit) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text(unit.rawValue.uppercased()).tag(unit)
                            }
                        }
                        
                        Picker("Bodyweight Unit", selection: Bindable(settings).bodyweightUnit) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text(unit.rawValue.uppercased()).tag(unit)
                            }
                        }
                        
                        Picker("Default Rest Timer", selection: Bindable(settings).defaultRestSeconds) {
                            Text("60 Sec").tag(60)
                            Text("90 Sec").tag(90)
                            Text("120 Sec").tag(120)
                            Text("180 Sec").tag(180)
                        }
                    }
                    .listRowBackground(Color(white: 0.1))
                    
                    Section("Haptics & Sound") {
                        Toggle("Haptics Enabled", isOn: Bindable(settings).hapticsEnabled)
                        Toggle("Sounds Enabled", isOn: Bindable(settings).soundsEnabled)
                    }
                    .listRowBackground(Color(white: 0.1))
                    .tint(.green)
                    
                    Section("Social & Aesthetics") {
                        Picker("Default Share Style", selection: Bindable(settings).defaultShareCardStyle) {
                            ForEach(ShareCardStyle.allCases) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                    }
                    .listRowBackground(Color(white: 0.1))
                    
                    Section("Apple Health") {
                        Button(action: requestHealthKitAccess) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("Sync Health Data")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .listRowBackground(Color(white: 0.1))
                    
                    Section("Data Management") {
                        Button(action: exportAllData) {
                            Label("Export Data (CSV Summary)", systemImage: "square.and.arrow.up")
                                .foregroundColor(.green)
                        }
                        
                        Button(role: .destructive, action: {
                            showingResetAlert = true
                            HapticsService.shared.triggerImpact(style: .heavy)
                        }) {
                            Label("Reset All Data", systemImage: "trash.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .listRowBackground(Color(white: 0.1))
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Delete Everything", role: .destructive, action: resetAllData)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action is irreversible. All of your custom templates, workouts, weight logs, and personal records will be completely deleted.")
            }
            .alert("Health Access Requested", isPresented: $showingHealthSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Lift requested access to read/write weight measurements. Please check Apple Health settings if data doesn't sync.")
            }
            .alert("HealthKit Unavailable", isPresented: $showingHealthErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(healthErrorMessage)
            }
            .sheet(isPresented: $showingExportSheet) {
                ActivityViewController(activityItems: [exportText])
                    .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Actions
    private func requestHealthKitAccess() {
        HapticsService.shared.triggerImpact(style: .light)
        
        guard HealthKitService.shared.isAvailable else {
            healthErrorMessage = "Apple Health is not available on this device configuration."
            showingHealthErrorAlert = true
            return
        }
        
        HealthKitService.shared.requestPermissions { success, error in
            if success {
                showingHealthSuccessAlert = true
            } else if let error = error {
                healthErrorMessage = error.localizedDescription
                showingHealthErrorAlert = true
            }
        }
    }
    
    private func exportAllData() {
        HapticsService.shared.triggerImpact(style: .light)
        
        var csv = "Date,Workout Name,Workout Type,Duration (sec),Volume (\(settings.weightUnit.rawValue)),Sets,Reps\n"
        let sortedWorkouts = workouts.sorted(by: { $0.date > $1.date })
        
        for w in sortedWorkouts {
            let nameEscaped = w.name.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\(w.date.formatted(date: .numeric, time: .shortened)),\"\(nameEscaped)\",\(w.type.rawValue),\(w.duration),\(w.totalVolume),\(w.totalSets),\(w.totalReps)\n"
        }
        
        exportText = csv
        showingExportSheet = true
    }
    
    private func resetAllData() {
        // Delete workouts
        for w in workouts { modelContext.delete(w) }
        // Delete bodyweight
        for b in bodyweight { modelContext.delete(b) }
        // Delete templates
        for t in templates { modelContext.delete(t) }
        // Delete PRs
        for p in prs { modelContext.delete(p) }
        
        // Re-preload built-in exercises and templates
        StorageService.preloadExercises(context: modelContext)
        
        try? modelContext.save()
        HapticsService.shared.triggerNotification(type: .success)
    }
}
