import SwiftUI
import SwiftData

public struct MainTabView: View {
    @State private var sessionManager = WorkoutSessionManager.shared
    @State private var selectedTab = 0
    @State private var showActiveWorkoutModal = false
    @State private var shareCardPR: PersonalRecord?
    @State private var showPRSharePreview = false
    
    @Query(sort: \Workout.date, order: .reverse) private var allWorkouts: [Workout]
    @Query(sort: \BodyweightEntry.date, order: .reverse) private var bodyweightEntries: [BodyweightEntry]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                StartWorkoutView()
                    .tabItem {
                        Label("Workouts", systemImage: "dumbbell.fill")
                    }
                    .tag(1)
                
                CalendarView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(2)
                
                ProgressView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.xyaxis.line")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(.green)
            
            // Floating Active Workout Banner
            VStack {
                Spacer()
                if let activeWorkout = sessionManager.activeWorkout {
                    Button(action: {
                        showActiveWorkoutModal = true
                        HapticsService.shared.triggerImpact(style: .medium)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .padding(8)
                                .background(Color.green)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Workout in Progress")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.gray)
                                Text(activeWorkout.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Elapsed time
                            TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                                let duration = timeline.date.timeIntervalSince(activeWorkout.startTime)
                                Text(formatDuration(duration))
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                        .padding(.horizontal, 16)
                        // Make sure it sits just above the TabBar. Since TabBar is about 50-80pt,
                        // we can pad it a bit.
                        .padding(.bottom, 60)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(.keyboard)
            
            // PR Celebration Overlay
            if sessionManager.showPRCelebration {
                PRCelebrationView(
                    prs: sessionManager.lastUnlockedPRs,
                    onDismiss: {
                        sessionManager.showPRCelebration = false
                    },
                    onShare: { pr in
                        shareCardPR = pr
                        showPRSharePreview = true
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        // Sheet for active workout logging
        .fullScreenCover(isPresented: $showActiveWorkoutModal) {
            ActiveWorkoutView()
        }
        // Sheet for sharing PRs
        .sheet(isPresented: $showPRSharePreview) {
            if let pr = shareCardPR {
                ShareCardPreviewView(
                    type: .pr,
                    pr: pr,
                    bodyweightEntries: bodyweightEntries,
                    streakCount: calculateStreak()
                )
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let mins = (Int(duration) % 3600) / 60
        let secs = Int(duration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, mins, secs)
        }
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func calculateStreak() -> Int {
        // Simple streak calc for presentation (workouts per week)
        guard !allWorkouts.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        let sortedWorkouts = allWorkouts.sorted { $0.date > $1.date }
        
        var currentSearchDate = Date()
        
        for _ in 0..<52 { // Max 1 year
            // Check if there's a workout in the week of currentSearchDate
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentSearchDate)?.start ?? currentSearchDate
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentSearchDate)?.end ?? currentSearchDate
            
            let hasWorkout = sortedWorkouts.contains { w in
                w.date >= startOfWeek && w.date < endOfWeek
            }
            
            if hasWorkout {
                streak += 1
                // Move back 1 week
                if let prevWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentSearchDate) {
                    currentSearchDate = prevWeek
                } else {
                    break
                }
            } else {
                // Streak broken (only break if it's not the current week, as the current week is still in progress)
                let isCurrentWeek = calendar.isDate(currentSearchDate, equalTo: Date(), toGranularity: .weekOfYear)
                if isCurrentWeek {
                    // Check previous week instead to see if streak is still active
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
}
