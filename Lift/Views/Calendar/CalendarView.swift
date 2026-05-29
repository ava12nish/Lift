import SwiftUI
import SwiftData

public struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    @State private var selectedDate = Date()
    @State private var currentMonthDate = Date()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Month Selector Header
                        monthSelectorHeader
                        
                        // Weekday Names Row
                        weekdayNamesRow
                        
                        // Days Grid
                        daysGrid
                        
                        // Selected Day Workouts List
                        selectedDayWorkoutsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Workout Calendar")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .tracking(1)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Month Selector Header
    private var monthSelectorHeader: some View {
        HStack {
            Button(action: {
                changeMonth(by: -1)
                HapticsService.shared.triggerImpact(style: .light)
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color(white: 0.12))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(monthYearString(from: currentMonthDate))
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                changeMonth(by: 1)
                HapticsService.shared.triggerImpact(style: .light)
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color(white: 0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Weekday Headers
    private var weekdayNamesRow: some View {
        let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
        return HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Days Grid
    private var daysGrid: some View {
        let days = generateDaysInMonth(for: currentMonthDate)
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(date)
                    let dayWorkouts = workoutsForDay(date)
                    
                    Button(action: {
                        selectedDate = date
                        HapticsService.shared.triggerImpact(style: .light)
                    }) {
                        VStack(spacing: 4) {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.system(size: 14, weight: isSelected ? .bold : .semibold, design: .rounded))
                                .foregroundColor(isSelected ? .black : (isToday ? .green : .white))
                                .frame(width: 32, height: 32)
                                .background(isSelected ? Color.green : (isToday ? Color.green.opacity(0.15) : Color.clear))
                                .clipShape(Circle())
                            
                            // Workout Indicators
                            HStack(spacing: 3) {
                                ForEach(dayWorkouts.prefix(3)) { workout in
                                    Circle()
                                        .fill(indicatorColor(for: workout.type))
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                } else {
                    // Empty Cell for offsets
                    Spacer()
                        .frame(height: 42)
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.08))
        .cornerRadius(20)
    }
    
    // MARK: - Selected Day Workouts List
    private var selectedDayWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedDate.formatted(date: .long, time: .omitted).uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1.5)
                .padding(.top, 16)
            
            let dayWorkouts = workoutsForDay(selectedDate)
            if dayWorkouts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                    Text("Rest Day")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("No workouts logged on this day.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.05))
                .cornerRadius(16)
            } else {
                ForEach(dayWorkouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.type.rawValue.uppercased())
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(indicatorColor(for: workout.type))
                                        .tracking(1)
                                    
                                    Text(workout.name)
                                        .font(.system(size: 18, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                Image(systemName: workout.type.iconName)
                                    .font(.system(size: 18))
                                    .foregroundColor(indicatorColor(for: workout.type))
                            }
                            
                            HStack(spacing: 16) {
                                Text("\(formatDuration(workout.duration))")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.gray)
                                
                                Text("\(Int(workout.totalVolume)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.gray)
                                
                                Text("\(workout.totalSets) Sets")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            
                            // Key exercises completed
                            Text(workout.exercises.map { $0.exerciseName }.joined(separator: ", "))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .lineLimit(1)
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
            }
        }
    }
    
    // MARK: - Month maths & Helpers
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonthDate) {
            currentMonthDate = newDate
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        // Convert weekday to start Monday instead of Sunday
        // Sunday (1) = 6 offset, Monday (2) = 0 offset, Tuesday (3) = 1 offset...
        let startOffset = (weekdayOfFirst + 5) % 7
        
        var days: [Date?] = Array(repeating: nil, count: startOffset)
        
        for day in 1...monthRange.count {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(dayDate)
            }
        }
        
        return days
    }
    
    private func workoutsForDay(_ date: Date) -> [Workout] {
        let calendar = Calendar.current
        return workouts.filter { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }
    }
    
    private func indicatorColor(for type: WorkoutType) -> Color {
        switch type {
        case .push: return .green
        case .pull: return .cyan
        case .legs: return .orange
        case .cardio: return .blue
        default: return .yellow
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        return "\(mins) min"
    }
}
