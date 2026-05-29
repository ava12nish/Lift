import SwiftUI
import SwiftData

public struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query(sort: \BodyweightEntry.date, order: .reverse) private var bodyweightEntries: [BodyweightEntry]
    @Query(sort: \PersonalRecord.date, order: .reverse) private var prs: [PersonalRecord]
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]
    
    @State private var showingAddWeightSheet = false
    @State private var newWeightString = ""
    @State private var showingQuickStart = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Greeting & Date
                        headerSection
                        
                        // Main Action: Start Workout
                        startWorkoutCard
                        
                        // Weekly Summary Section (Streak, Day indicators, Stats)
                        weeklyOverviewSection
                        
                        // Recent PR Highlight
                        latestPRCard
                        
                        // Bodyweight Trend Card
                        bodyweightTrendCard
                        
                        // Quick Start Recent Workout
                        quickStartRecentSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Space for active workout banner
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.green)
                        Text("LIFT")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .tracking(3)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddWeightSheet) {
                addWeightSheet
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
            
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.top, 16)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning, Lifter" }
        if hour < 18 { return "Good Afternoon, Lifter" }
        return "Good Evening, Lifter"
    }
    
    // MARK: - Start Workout Card
    private var startWorkoutCard: some View {
        Button(action: {
            WorkoutSessionManager.shared.startNewWorkout(name: "Quick Session", type: .custom, context: modelContext)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("READY TO TRAIN?")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                        .tracking(1.5)
                    
                    Text("Start Empty Workout")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Log exercises, sets, and reps dynamically.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
            }
            .padding(20)
            .background(Color(white: 0.08))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: [.green.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
            )
        }
    }
    
    // MARK: - Weekly Overview
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("THIS WEEK")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1)
                
                Spacer()
                
                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text("\(calculateStreak()) Week Streak")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(12)
            }
            
            // Monday to Sunday Circles
            HStack(spacing: 12) {
                ForEach(daysOfWeekShort, id: \.self) { day in
                    let workedOut = checkWorkout(onDay: day)
                    VStack(spacing: 6) {
                        Text(dayName(day))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Circle()
                            .fill(workedOut ? Color.green : Color(white: 0.12))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: workedOut ? "checkmark" : "")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            
            // Weekly stats row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VOLUME")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(Int(weeklyVolume)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("SESSIONS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(weeklySessionsCount) times")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL SETS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(weeklySetsCount) Sets")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color(white: 0.05))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Latest PR
    private var latestPRCard: some View {
        Group {
            if let latestPR = prs.first {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("LATEST PERSONAL RECORD", systemImage: "trophy.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                            .tracking(1)
                        
                        Spacer()
                        
                        Text(latestPR.date.formatted(.dateTime.day().month()))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(latestPR.exerciseName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            if latestPR.typeString == "weight" {
                                Text("\(Int(latestPR.weight)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                                    .font(.system(size: 26, weight: .black))
                                    .foregroundColor(.yellow)
                            } else if latestPR.typeString == "oneRepMax" {
                                Text("\(Int(latestPR.value)) \(UserSettingsManager.shared.weightUnit.rawValue) (1RM)")
                                    .font(.system(size: 26, weight: .black))
                                    .foregroundColor(.yellow)
                            } else if latestPR.typeString == "reps" {
                                Text("\(Int(latestPR.value)) Reps @ \(Int(latestPR.weight)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.yellow.opacity(0.8))
                    }
                }
                .padding(16)
                .background(Color(white: 0.08))
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - Bodyweight Trend
    private var bodyweightTrendCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("BODYWEIGHT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1)
                
                if let latestWeight = bodyweightEntries.first {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f", latestWeight.weight))
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text(UserSettingsManager.shared.bodyweightUnit.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("No weight logged yet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingAddWeightSheet = true
                HapticsService.shared.triggerImpact(style: .light)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Log")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(white: 0.08))
        .cornerRadius(16)
    }
    
    // MARK: - Quick Start Recent
    private var quickStartRecentSection: some View {
        Group {
            if let lastWorkout = workouts.first {
                VStack(alignment: .leading, spacing: 12) {
                    Text("REPEAT RECENT WORKOUT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    Button(action: {
                        repeatWorkout(lastWorkout)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(lastWorkout.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("\(lastWorkout.exercises.count) Exercises • \(lastWorkout.totalSets) Sets")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.green)
                        }
                        .padding(16)
                        .background(Color(white: 0.05))
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    // MARK: - Add Weight Sheet
    private var addWeightSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Log Today's Bodyweight")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    HStack(spacing: 8) {
                        TextField("0.0", text: $newWeightString)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: 150)
                            .padding(.vertical, 8)
                            .background(Color(white: 0.12))
                            .cornerRadius(16)
                        
                        Text(UserSettingsManager.shared.bodyweightUnit.rawValue)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: saveWeight) {
                        Text("Log Weight")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .cornerRadius(14)
                    }
                    .disabled(Double(newWeightString) == nil)
                    
                    // Option to sync with healthkit
                    if HealthKitService.shared.isAvailable {
                        Button(action: syncFromHealthKit) {
                            HStack {
                                Image(systemName: "heart.text.square.fill")
                                    .foregroundColor(.red)
                                Text("Sync from Apple Health")
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.08))
                            .cornerRadius(14)
                        }
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddWeightSheet = false
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Streak & Date Maths
    private func calculateStreak() -> Int {
        guard !workouts.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        
        var currentSearchDate = Date()
        
        for _ in 0..<52 {
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentSearchDate)?.start ?? currentSearchDate
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentSearchDate)?.end ?? currentSearchDate
            
            let hasWorkout = sortedWorkouts.contains { w in
                w.date >= startOfWeek && w.date < endOfWeek
            }
            
            if hasWorkout {
                streak += 1
                if let prevWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentSearchDate) {
                    currentSearchDate = prevWeek
                } else {
                    break
                }
            } else {
                let isCurrentWeek = calendar.isDate(currentSearchDate, equalTo: Date(), toGranularity: .weekOfYear)
                if isCurrentWeek {
                    if let prevWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentSearchDate) {
                        currentSearchDate = prevWeek
                        let hasWorkoutPrev = sortedWorkouts.contains { w in
                            let s = calendar.dateInterval(of: .weekOfYear, for: prevWeek)?.start ?? prevWeek
                            let e = calendar.dateInterval(of: .weekOfYear, for: prevWeek)?.end ?? prevWeek
                            return w.date >= s && w.date < e
                        }
                        if hasWorkoutPrev {
                            continue
                        }
                    }
                }
                break
            }
        }
        return max(streak, 1)
    }
    
    private var daysOfWeekShort: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today) // 1 = Sunday, 2 = Monday...
        
        // Let's get Mon (2) to Sun (1)
        // Adjust so Monday is first
        let mondayOffset = (dayOfWeek + 5) % 7 // Monday = 0, Sunday = 6
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else {
            return []
        }
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }
    
    private func dayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).first ?? "M")
    }
    
    private func checkWorkout(onDay date: Date) -> Bool {
        let calendar = Calendar.current
        return workouts.contains { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }
    }
    
    private var weeklyVolume: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        let mondayOffset = (dayOfWeek + 5) % 7
        guard let startOfWeek = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else {
            return 0
        }
        return workouts.filter { $0.date >= startOfWeek }.reduce(0) { $0 + $1.totalVolume }
    }
    
    private var weeklySessionsCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        let mondayOffset = (dayOfWeek + 5) % 7
        guard let startOfWeek = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else {
            return 0
        }
        return workouts.filter { $0.date >= startOfWeek }.count
    }
    
    private var weeklySetsCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        let mondayOffset = (dayOfWeek + 5) % 7
        guard let startOfWeek = calendar.date(byAdding: .day, value: -mondayOffset, to: today) else {
            return 0
        }
        return workouts.filter { $0.date >= startOfWeek }.reduce(0) { $0 + $1.totalSets }
    }
    
    // MARK: - Actions
    private func saveWeight() {
        guard let weightVal = Double(newWeightString) else { return }
        let entry = BodyweightEntry(weight: weightVal)
        modelContext.insert(entry)
        
        // Try writing to Apple Health
        if HealthKitService.shared.isAvailable {
            HealthKitService.shared.saveBodyweight(weight: weightVal, date: Date()) { _, _ in }
        }
        
        try? modelContext.save()
        newWeightString = ""
        showingAddWeightSheet = false
        HapticsService.shared.triggerNotification(type: .success)
    }
    
    private func syncFromHealthKit() {
        HealthKitService.shared.requestPermissions { success, _ in
            if success {
                HealthKitService.shared.fetchLatestBodyweight { weight, _, _ in
                    if let weight = weight {
                        newWeightString = String(format: "%.1f", weight)
                    }
                }
            }
        }
    }
    
    private func repeatWorkout(_ workout: Workout) {
        let newWorkout = Workout(
            date: Date(),
            startTime: Date(),
            name: workout.name,
            type: workout.type
        )
        modelContext.insert(newWorkout)
        
        // Copy sets/exercises
        for (i, we) in workout.exercises.enumerated() {
            let newWE = WorkoutExercise(
                exerciseId: we.exerciseId,
                exerciseName: we.exerciseName,
                muscleGroup: we.muscleGroup,
                trackingType: we.trackingType,
                orderIndex: i
            )
            newWorkout.exercises.append(newWE)
            modelContext.insert(newWE)
            
            for set in we.sets {
                let newSet = WorkoutSet(
                    setNumber: set.setNumber,
                    weight: set.weight,
                    reps: set.reps,
                    durationSeconds: set.durationSeconds,
                    distance: set.distance,
                    isWarmup: set.isWarmup,
                    isCompleted: false // User starts fresh
                )
                newWE.sets.append(newSet)
                modelContext.insert(newSet)
            }
        }
        
        WorkoutSessionManager.shared.activeWorkout = newWorkout
        HapticsService.shared.triggerImpact(style: .medium)
    }
}
