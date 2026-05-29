import SwiftUI
import SwiftData

@main
struct LiftApp: App {
    let container: ModelContainer
    
    public init() {
        do {
            let schema = Schema([
                Workout.self,
                WorkoutExercise.self,
                WorkoutSet.self,
                Exercise.self,
                BodyweightEntry.self,
                PersonalRecord.self,
                WorkoutTemplate.self,
                TemplateExercise.self,
                TemplateSet.self,
                Achievement.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
            
            // Seed the built-in library on launch
            let context = container.mainContext
            Task { @MainActor in
                StorageService.preloadExercises(context: context)
            }
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error.localizedDescription)")
        }
    }
    
    @State private var settings = UserSettingsManager.shared
    @State private var showSplash = true
    
    public var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(settings.colorScheme)
            .modelContainer(container)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
