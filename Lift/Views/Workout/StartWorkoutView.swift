import SwiftUI
import SwiftData

public struct StartWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    
    @State private var showingCreateTemplateSheet = false
    @State private var showingEditTemplateSheet = false
    @State private var templateToEdit: WorkoutTemplate?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Start Workout")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 16)
                        
                        // Empty Workout Trigger
                        quickStartButton
                        
                        // Templates Header
                        templatesHeader
                        
                        // Templates Grid/List
                        if templates.isEmpty {
                            emptyTemplatesState
                        } else {
                            templatesList
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCreateTemplateSheet) {
                CreateTemplateView()
            }
            .sheet(item: $templateToEdit) { template in
                CreateTemplateView(editingTemplate: template)
            }
        }
    }
    
    // MARK: - Quick Start
    private var quickStartButton: some View {
        Button(action: {
            WorkoutSessionManager.shared.startNewWorkout(name: "Empty Workout", type: .custom, context: modelContext)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("START A NEW WORKOUT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                        .tracking(1.5)
                    
                    Text("Start Empty Workout")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Design your workout on the fly.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
            }
            .padding(18)
            .background(Color(white: 0.08))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Templates Header
    private var templatesHeader: some View {
        HStack {
            Text("TEMPLATES")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1.5)
            
            Spacer()
            
            Button(action: {
                showingCreateTemplateSheet = true
                HapticsService.shared.triggerImpact(style: .light)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Create")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.12))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Empty Templates State
    private var emptyTemplatesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.3x1.folder.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No Templates Found")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text("Create a workout template to quickly reuse your routine next time.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Templates List
    private var templatesList: some View {
        VStack(spacing: 16) {
            ForEach(templates) { template in
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.type.rawValue.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                                .tracking(1)
                            Text(template.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Edit & Delete Options
                        Menu {
                            Button(action: {
                                templateToEdit = template
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                deleteTemplate(template)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                    }
                    
                    // Exercise List Summary
                    VStack(alignment: .leading, spacing: 6) {
                        if template.exercises.isEmpty {
                            Text("No exercises added")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        } else {
                            // Sort by orderIndex
                            let sortedEx = template.exercises.sorted { $0.orderIndex < $1.orderIndex }
                            ForEach(sortedEx.prefix(4)) { ex in
                                Text("• \(ex.exerciseName) (\(ex.sets.count) sets)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            if template.exercises.count > 4 {
                                Text("+ \(template.exercises.count - 4) more...")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 4)
                    
                    // Start Button
                    Button(action: {
                        WorkoutSessionManager.shared.startWorkoutFromTemplate(template, context: modelContext)
                    }) {
                        Text("Start Workout")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
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
    
    // MARK: - Actions
    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
        HapticsService.shared.triggerImpact(style: .medium)
    }
}
