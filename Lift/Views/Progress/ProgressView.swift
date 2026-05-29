import SwiftUI
import Charts
import SwiftData

public struct ProgressView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query(sort: \BodyweightEntry.date, order: .reverse) private var bodyweightEntries: [BodyweightEntry]
    @Query(sort: \PersonalRecord.date, order: .reverse) private var prs: [PersonalRecord]
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    
    @State private var progressTab = 0 // 0 = Charts, 1 = Bodyweight, 2 = PRs
    
    // Exercise selector for PR chart
    @State private var selectedPRChartExercise: String = "Bench Press"
    
    // Bodyweight log states
    @State private var showingAddWeight = false
    @State private var bodyweightInput = ""
    @State private var shareCardPR: PersonalRecord?
    @State private var showingPRShare = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Segmented Control
                    Picker("Progress Selector", selection: $progressTab) {
                        Text("Charts").tag(0)
                        Text("Weight").tag(1)
                        Text("PRs").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            switch progressTab {
                            case 0:
                                chartsTabContent
                            case 1:
                                weightTabContent
                            case 2:
                                prsTabContent
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Analytics & Logs")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            .sheet(isPresented: $showingAddWeight) {
                addWeightSheet
            }
            .sheet(isPresented: $showingPRShare) {
                if let pr = shareCardPR {
                    ShareCardPreviewView(
                        type: .pr,
                        pr: pr,
                        bodyweightEntries: bodyweightEntries,
                        streakCount: 3
                    )
                }
            }
            .onAppear {
                // Pick first available exercise name for the chart picker if default isn't in DB
                if !allExercises.isEmpty && !allExercises.contains(where: { $0.name == selectedPRChartExercise }) {
                    selectedPRChartExercise = allExercises.first?.name ?? "Bench Press"
                }
            }
        }
    }
    
    // MARK: - CHARTS TAB
    private var chartsTabContent: some View {
        VStack(spacing: 24) {
            // 1. Bodyweight Chart
            chartCard(title: "Bodyweight Trends") {
                if bodyweightEntries.isEmpty {
                    emptyChartPlaceholder(msg: "Log your weight to view trends.")
                } else {
                    let sortedEntries = bodyweightEntries.sorted(by: { $0.date < $1.date })
                    Chart(sortedEntries) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color.green)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color.green)
                    }
                    .chartYScale(domain: (sortedEntries.map { $0.weight }.min() ?? 100) - 5 ... (sortedEntries.map { $0.weight }.max() ?? 200) + 5)
                    .frame(height: 180)
                }
            }
            
            // 2. Muscle Group Volume
            chartCard(title: "Sets per Muscle Group") {
                let muscleSets = calculateMuscleGroupSets()
                if muscleSets.isEmpty {
                    emptyChartPlaceholder(msg: "Complete workouts to see muscle distribution.")
                } else {
                    Chart(muscleSets, id: \.key) { key, value in
                        BarMark(
                            x: .value("Sets", value),
                            y: .value("Muscle", key)
                        )
                        .foregroundStyle(Color.cyan)
                        .cornerRadius(6)
                    }
                    .frame(height: 180)
                }
            }
            
            // 3. Exercise specific PR Chart
            chartCard(title: "PR Progress: \(selectedPRChartExercise)") {
                VStack(spacing: 12) {
                    Picker("Select Lift", selection: $selectedPRChartExercise) {
                        ForEach(allExercises) { ex in
                            Text(ex.name).tag(ex.name)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.green)
                    
                    let exercisePRs = prs.filter { $0.exerciseName == selectedPRChartExercise && $0.typeString == "weight" }.sorted(by: { $0.date < $1.date })
                    
                    if exercisePRs.isEmpty {
                        emptyChartPlaceholder(msg: "No PR records for \(selectedPRChartExercise) yet.")
                    } else {
                        Chart(exercisePRs) { record in
                            LineMark(
                                x: .value("Date", record.date),
                                y: .value("Weight", record.weight)
                            )
                            .foregroundStyle(Color.yellow)
                            .interpolationMethod(.linear)
                            
                            PointMark(
                                x: .value("Date", record.date),
                                y: .value("Weight", record.weight)
                            )
                            .foregroundStyle(Color.yellow)
                        }
                        .frame(height: 140)
                    }
                }
            }
            
            // 4. Workout Frequency
            chartCard(title: "Workouts Frequency") {
                let freq = calculateWeeklyFrequency()
                if freq.isEmpty {
                    emptyChartPlaceholder(msg: "Complete workouts to see consistency trends.")
                } else {
                    Chart(freq, id: \.weekLabel) { item in
                        BarMark(
                            x: .value("Week Starting", item.weekLabel),
                            y: .value("Frequency", item.count)
                        )
                        .foregroundStyle(Color.green)
                        .cornerRadius(6)
                    }
                    .frame(height: 160)
                }
            }
        }
    }
    
    // MARK: - WEIGHT TAB
    private var weightTabContent: some View {
        VStack(spacing: 16) {
            HStack {
                Text("WEIGHT LOG HISTORY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1)
                
                Spacer()
                
                Button(action: {
                    showingAddWeight = true
                    HapticsService.shared.triggerImpact(style: .light)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add weight")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
                }
            }
            
            if bodyweightEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "scale.3d")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No weight logs yet")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            } else {
                ForEach(bodyweightEntries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date.formatted(date: .long, time: .omitted))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            Text(entry.date.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "%.1f %@", entry.weight, UserSettingsManager.shared.bodyweightUnit.rawValue))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteWeight(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - PRS TAB
    private var prsTabContent: some View {
        VStack(spacing: 16) {
            Text("PERSONAL RECORDS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1)
            
            if prs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No PRs locked in yet")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Log workouts. Lift heavier. Hit milestones.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            } else {
                ForEach(prs) { pr in
                    HStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                            .padding(12)
                            .background(Color.yellow.opacity(0.12))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pr.exerciseName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            HStack {
                                if pr.typeString == "weight" {
                                    Text("\(Int(pr.weight)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                                } else if pr.typeString == "oneRepMax" {
                                    Text("\(Int(pr.value)) \(UserSettingsManager.shared.weightUnit.rawValue) (1RM)")
                                } else if pr.typeString == "reps" {
                                    Text("\(Int(pr.value)) Reps @ \(Int(pr.weight)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                                } else if pr.typeString == "dailyVolume" {
                                    Text("\(Int(pr.value)) Daily Volume")
                                }
                                
                                Text("•")
                                    .foregroundColor(.gray)
                                Text(pr.date.formatted(.dateTime.day().month().year()))
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Share PR Button
                        Button(action: {
                            shareCardPR = pr
                            showingPRShare = true
                            HapticsService.shared.triggerImpact(style: .light)
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                                .padding(8)
                                .background(Color.primary.opacity(0.05))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.03), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Add Weight Sheet
    private var addWeightSheet: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Add Weight Measurement")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    HStack(spacing: 8) {
                        TextField("0.0", text: $bodyweightInput)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .frame(width: 150)
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(16)
                        
                        Text(UserSettingsManager.shared.bodyweightUnit.rawValue)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: saveWeight) {
                        Text("Save Log")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .cornerRadius(14)
                    }
                    .disabled(Double(bodyweightInput) == nil)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddWeight = false
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Analytics Helpers
    private func calculateMuscleGroupSets() -> [(key: String, value: Int)] {
        var countMap: [String: Int] = [:]
        for workout in workouts {
            for exercise in workout.exercises {
                let name = exercise.muscleGroup.rawValue
                countMap[name, default: 0] += exercise.completedSetsCount
            }
        }
        return countMap.sorted { $0.value > $1.value }
    }
    
    struct WeekFreqItem {
        let weekLabel: String
        let count: Int
    }
    
    private func calculateWeeklyFrequency() -> [WeekFreqItem] {
        guard !workouts.isEmpty else { return [] }
        
        let calendar = Calendar.current
        var freqMap: [String: Int] = [:]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        
        for workout in workouts {
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: workout.date)?.start ?? workout.date
            let label = formatter.string(from: startOfWeek)
            freqMap[label, default: 0] += 1
        }
        
        // Take the 5 most recent weeks
        let sortedKeys = freqMap.keys.sorted { k1, k2 in
            guard let d1 = formatter.date(from: k1), let d2 = formatter.date(from: k2) else { return false }
            return d1 < d2
        }
        
        return sortedKeys.suffix(5).map { WeekFreqItem(weekLabel: $0, count: freqMap[$0] ?? 0) }
    }
    
    // MARK: - Actions
    private func saveWeight() {
        guard let value = Double(bodyweightInput) else { return }
        let entry = BodyweightEntry(weight: value)
        modelContext.insert(entry)
        
        if HealthKitService.shared.isAvailable {
            HealthKitService.shared.saveBodyweight(weight: value, date: Date()) { _, _ in }
        }
        
        try? modelContext.save()
        bodyweightInput = ""
        showingAddWeight = false
        HapticsService.shared.triggerNotification(type: .success)
    }
    
    private func deleteWeight(_ entry: BodyweightEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
        HapticsService.shared.triggerImpact(style: .medium)
    }
    
    // MARK: - Templates / View Builders
    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
            
            content()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
    
    private func emptyChartPlaceholder(msg: String) -> some View {
        VStack {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 24))
                .foregroundColor(.gray)
                .padding(.bottom, 4)
            Text(msg)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
}
