import SwiftUI

public struct ShareCardConfig {
    public var style: ShareCardStyle = .neonLift
    public var isSquare: Bool = true // true = 1:1, false = 9:16 (story)
    public var showVolume: Bool = true
    public var showPRs: Bool = true
    public var showWatermark: Bool = true
    public var accentColor: Color = .green
}

// Global branding overlay
struct LiftWatermarkView: View {
    let show: Bool
    let isDark: Bool
    
    var body: some View {
        if show {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(isDark ? .green : .orange)
                    .font(.system(size: 14, weight: .bold))
                Text("L I F T")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundColor(isDark ? .white : .black)
            }
            .padding(.bottom, 16)
        }
    }
}

// Background generator based on style
struct ShareCardBackground: View {
    let style: ShareCardStyle
    
    var body: some View {
        switch style {
        case .darkPremium:
            LinearGradient(
                colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color(white: 0.2), lineWidth: 1)
            )
        case .neonLift:
            Color.black
                .overlay(
                    RadialGradient(
                        colors: [Color.green.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 350
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(LinearGradient(colors: [.green, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                )
        case .minimalWhite:
            Color.white
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color(white: 0.9), lineWidth: 1)
                )
        case .performanceStats:
            Color(white: 0.08)
                .overlay(
                    // Tech grid look
                    GridPattern()
                        .stroke(Color.orange.opacity(0.08), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        case .prCelebration:
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.05, blue: 0.25), Color(red: 0.05, green: 0.0, blue: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                RadialGradient(
                    colors: [Color.yellow.opacity(0.18), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.yellow.opacity(0.4), lineWidth: 1.5)
            )
        }
    }
}

// Helper grid pattern for performance stats background
struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step: CGFloat = 20
        for x in stride(from: 0, to: rect.width, by: step) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for y in stride(from: 0, to: rect.height, by: step) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}

// Master Sharing Card Container
public struct MasterShareCardView: View {
    let type: ShareCardType
    let config: ShareCardConfig
    
    // Data objects
    let workout: Workout?
    let pr: PersonalRecord?
    let bodyweightEntries: [BodyweightEntry]
    let streakCount: Int
    
    public init(
        type: ShareCardType,
        config: ShareCardConfig,
        workout: Workout? = nil,
        pr: PersonalRecord? = nil,
        bodyweightEntries: [BodyweightEntry] = [],
        streakCount: Int = 1
    ) {
        self.type = type
        self.config = config
        self.workout = workout
        self.pr = pr
        self.bodyweightEntries = bodyweightEntries
        self.streakCount = streakCount
    }
    
    private var isDarkStyle: Bool {
        config.style != .minimalWhite
    }
    
    private var textColor: Color {
        isDarkStyle ? .white : .black
    }
    
    private var subtextColor: Color {
        isDarkStyle ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    private var accentColor: Color {
        switch config.style {
        case .darkPremium: return Color(red: 0.85, green: 0.7, blue: 0.4) // Champagne/Gold
        case .neonLift: return .green
        case .minimalWhite: return .black
        case .performanceStats: return .orange
        case .prCelebration: return .yellow
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main Content Area
            Spacer()
            
            VStack(spacing: 20) {
                switch type {
                case .workout:
                    workoutCardView
                case .pr:
                    prCardView
                case .weekly:
                    weeklyCardView
                case .bodyweight:
                    bodyweightCardView
                case .streak:
                    streakCardView
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Bottom Watermark
            LiftWatermarkView(show: config.showWatermark, isDark: isDarkStyle)
        }
        .frame(width: 360, height: config.isSquare ? 360 : 640)
        .background(ShareCardBackground(style: config.style))
        .clipShape(RoundedRectangle(cornerRadius: config.isSquare ? 20 : 0))
    }
    
    // MARK: - Workout Summary Card
    private var workoutCardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout?.type.rawValue.uppercased() ?? "WORKOUT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundColor(accentColor)
                    
                    Text(workout?.name ?? "Daily Session")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(textColor)
                }
                Spacer()
                
                Image(systemName: workout?.type.iconName ?? "flame")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
            }
            
            Text(workout?.date.formatted(date: .abbreviated, time: .shortened) ?? Date().formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(subtextColor)
            
            Divider()
                .background(textColor.opacity(0.15))
                .padding(.vertical, 4)
            
            // Stats Row
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("TIME")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(subtextColor)
                    Text(formatDuration(workout?.duration ?? 2700))
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                        .foregroundColor(textColor)
                }
                
                if config.showVolume {
                    VStack(alignment: .leading) {
                        Text("VOLUME")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(subtextColor)
                        Text("\(Int(workout?.totalVolume ?? 8450)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                            .font(.system(size: 18, weight: .heavy, design: .monospaced))
                            .foregroundColor(textColor)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("SETS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(subtextColor)
                    Text("\(workout?.totalSets ?? 12)")
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                        .foregroundColor(textColor)
                }
            }
            
            // Top Exercises Completed
            VStack(alignment: .leading, spacing: 6) {
                Text("KEY LIFTS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(subtextColor)
                    .padding(.top, 6)
                
                if let exercises = workout?.exercises, !exercises.isEmpty {
                    ForEach(Array(exercises.prefix(3).enumerated()), id: \.offset) { _, exercise in
                        HStack {
                            Text(exercise.exerciseName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(textColor)
                            Spacer()
                            
                            // Top set weight/reps
                            if let topSet = exercise.sets.filter({ $0.isCompleted }).max(by: { $0.weight < $1.weight }) {
                                Text("\(Int(topSet.weight))x\(topSet.reps)")
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                } else {
                    // Fallback preview
                    HStack {
                        Text("Bench Press")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textColor)
                        Spacer()
                        Text("225 lb x 5")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(accentColor)
                    }
                    HStack {
                        Text("Incline Dumbbell Press")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textColor)
                        Spacer()
                        Text("85 lb x 8")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(accentColor)
                    }
                }
            }
            
            if config.showPRs && (workout?.totalVolume ?? 1) > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 12))
                    Text("New personal records achieved")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Personal Record Card
    private var prCardView: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(accentColor)
                .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("NEW RECORD DETECTED")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundColor(accentColor)
            
            Text(pr?.exerciseName ?? "Squat")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 4) {
                if pr?.typeString == "weight" || pr?.typeString == "oneRepMax" || pr?.typeString == "reps" {
                    Text("\(Int(pr?.weight ?? 315)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(textColor)
                    
                    if let reps = pr?.reps, reps > 0 {
                        Text("FOR \(reps) \(reps == 1 ? "REP" : "REPS")")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(subtextColor)
                    }
                    
                    if let estimated1RM = pr?.estimatedOneRepMax, estimated1RM > 0 {
                        Text("Estimated 1RM: \(Int(estimated1RM)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accentColor)
                            .padding(.top, 4)
                    }
                } else if pr?.typeString == "dailyVolume" || pr?.typeString == "exerciseVolume" {
                    Text("\(Int(pr?.value ?? 12500)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(textColor)
                    
                    Text("TOTAL VOLUME RECORD")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(subtextColor)
                } else if pr?.typeString == "duration" {
                    Text(formatDuration(pr?.value ?? 5400))
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(textColor)
                    
                    Text("LONGEST WORKOUT RECORD")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(subtextColor)
                }
            }
            .padding(.vertical, 8)
            
            Text(pr?.date.formatted(date: .long, time: .omitted) ?? Date().formatted(date: .long, time: .omitted))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(subtextColor)
        }
    }
    
    // MARK: - Weekly Recap Card
    private var weeklyCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("WEEKLY SUMMARY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundColor(accentColor)
                Text("Consistency check.")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(textColor)
            }
            
            Divider()
                .background(textColor.opacity(0.15))
            
            // Grid of Stats
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WORKOUTS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(subtextColor)
                        Text("4 Sessions")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(textColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("TOTAL VOLUME")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(subtextColor)
                        Text("32,450 lb")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(textColor)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL SETS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(subtextColor)
                        Text("48 Sets Completed")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(textColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("FOCUS AREA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(subtextColor)
                        Text("Chest & Back")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(accentColor)
                    }
                }
            }
            .padding(.vertical, 6)
            
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(subtextColor)
                Text("Past 7 Days")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(subtextColor)
            }
        }
    }
    
    // MARK: - Bodyweight Progress Card
    private var bodyweightCardView: some View {
        VStack(spacing: 16) {
            Image(systemName: "scale.3d")
                .font(.system(size: 40))
                .foregroundColor(accentColor)
            
            VStack(spacing: 4) {
                Text("BODYWEIGHT LOG")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundColor(accentColor)
                Text("Progress Tracker")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(textColor)
            }
            
            Divider()
                .background(textColor.opacity(0.15))
                .padding(.horizontal, 20)
            
            HStack(spacing: 40) {
                if bodyweightEntries.count >= 2 {
                    let sorted = bodyweightEntries.sorted(by: { $0.date < $1.date })
                    let start = sorted.first!.weight
                    let current = sorted.last!.weight
                    let diff = current - start
                    
                    VStack(spacing: 4) {
                        Text("START")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(subtextColor)
                        Text(String(format: "%.1f %@", start, UserSettingsManager.shared.bodyweightUnit.rawValue))
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(textColor)
                    }
                    
                    VStack(spacing: 4) {
                        Text("CURRENT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(subtextColor)
                        Text(String(format: "%.1f %@", current, UserSettingsManager.shared.bodyweightUnit.rawValue))
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(textColor)
                    }
                    
                    VStack(spacing: 4) {
                        Text("DIFF")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(subtextColor)
                        Text(String(format: "%+.1f %@", diff, UserSettingsManager.shared.bodyweightUnit.rawValue))
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(diff <= 0 ? .green : .red)
                    }
                } else {
                    // Fallback
                    VStack(spacing: 4) {
                        Text("CURRENT WEIGHT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(subtextColor)
                        Text("185.4 lb")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(textColor)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Text(Date().formatted(date: .long, time: .omitted))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(subtextColor)
        }
    }
    
    // MARK: - Workout Streak Card
    private var streakCardView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.15), lineWidth: 6)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 44))
                    .foregroundColor(accentColor)
                    .shadow(color: accentColor.opacity(0.5), radius: 8, x: 0, y: 4)
            }
            
            VStack(spacing: 6) {
                Text("\(streakCount) WEEK STREAK")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(textColor)
                
                Text("STREAK MILESTONE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundColor(accentColor)
            }
            
            Text("“Discipline is choosing between what you want now and what you want most.”")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(textColor)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Text("Lift. Track. Repeat.")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(subtextColor)
                .tracking(1)
        }
    }
    
    // MARK: - Helpers
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
