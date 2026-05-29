# Lift — iOS Gym Tracker

Lift is a high-fidelity, App Store-quality fitness progress tracker designed for logging workouts, tracking sets, reps, weights, bodyweight, personal records (PRs), and visualizing gym progress over time. Built natively with **SwiftUI**, **SwiftData**, and **Swift Charts**, it offers a clean, fluid dark-mode user experience with haptics, system audio cues, and Apple Health integration.

---

## ✨ Features

- **Dynamic Workout Logging**: Track weights, reps, set types (warm-up vs. working sets), and exercise/workout notes in real time.
- **Smart suggestions**: Automatically view historical set performance (`135 lb x 8`) and suggested values on active sets.
- **Workout Templates**: Create, edit, and reorder custom templates (e.g., Push, Pull, Legs) to repeat routines instantly.
- **Custom Rest Timers**: Interactive countdown overlay with progress rings, audio beeps, and haptic notifications on set completion.
- **Trophy Milestones**: Interactive confetti overlay celebrating new personal records (weight, reps, estimated 1-Rep Max).
- **Progress Analytics**:
  - **Bodyweight Trends**: Spline graph tracking weight logs synced with Apple Health.
  - **Load Distribution**: Sets completed per target muscle group.
  - **Lift Progressions**: Track PR growth over time for specific lifts.
  - **Consistency Calendar**: Interactive month view highlighting workout dates.
- **High-Fidelity Sharing**: Export customized visual cards summarizing workouts, PRs, weight loss, or streaks.
- **Apple Health Integration**: Automatic read/write support for bodyweight data syncing.

---

## 🛠 Tech Stack

- **UI Framework**: SwiftUI
- **Database Engine**: SwiftData
- **Data Visualization**: Swift Charts
- **Frameworks**: HealthKit, AudioToolbox, ImageRenderer
- **Project Structure**: Configured via XcodeGen (`project.yml`)
- **Swift Version**: Swift 6 Strict Concurrency Safe

---

## 📂 Project Structure

```
Lift/
├── App/                # App Entrypoint & Database Seeding
├── Models/             # SwiftData Schemas (Workout, Exercise, Template, PR)
├── ViewModels/         # Session State Managers & Rest Timers
├── Services/           # HealthKit, Haptics, Audio, Suggestion Solvers
├── Utilities/          # Image Rendering Utilities
└── Views/              # Dashboards, Active Tracking, Calendar, Charts, Sharing Card views
```

---

## 🚀 Getting Started

### Prerequisites
- macOS Sonoma or newer
- Xcode 15.0+ (iOS 17.0+ deployment target)
- XcodeGen (optional, project already pre-generated)

### Running the App
1. Open `Lift.xcodeproj` in Xcode.
2. Select your target device or iOS Simulator (iOS 17.0+).
3. Press `Cmd + R` to build and run.
4. (Optional) Run `xcodegen` in the root folder to rebuild the project specification if `project.yml` is modified.
