import SwiftUI

public struct PRCelebrationView: View {
    let prs: [PersonalRecord]
    let onDismiss: () -> Void
    let onShare: (PersonalRecord) -> Void
    
    @State private var animateScale: CGFloat = 0.5
    @State private var animateOpacity: Double = 0.0
    @State private var animateGlow: CGFloat = 0.0
    
    public init(prs: [PersonalRecord], onDismiss: @escaping () -> Void, onShare: @escaping (PersonalRecord) -> Void) {
        self.prs = prs
        self.onDismiss = onDismiss
        self.onShare = onShare
    }
    
    public var body: some View {
        ZStack {
            // Dark Blur Background
            Color(.systemBackground).opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Celebration Icon
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(1.0 + (animateGlow * 0.15))
                    
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .opacity(0.8)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                }
                .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("PERSONAL RECORD!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(4)
                        .foregroundColor(.yellow)
                    
                    Text("New Peak Unlocked")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                // PRs ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(prs) { pr in
                            VStack(spacing: 16) {
                                Text(pr.exerciseName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: 4) {
                                    if pr.typeString == "weight" {
                                        Text("\(Int(pr.weight)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                                            .font(.system(size: 36, weight: .black))
                                            .foregroundColor(.yellow)
                                        Text("Max Weight Limit")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.gray)
                                    } else if pr.typeString == "oneRepMax" {
                                        Text("\(Int(pr.value)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                                            .font(.system(size: 36, weight: .black))
                                            .foregroundColor(.yellow)
                                        Text("Estimated 1RM")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.gray)
                                    } else if pr.typeString == "reps" {
                                        Text("\(Int(pr.value)) Reps")
                                            .font(.system(size: 36, weight: .black))
                                            .foregroundColor(.yellow)
                                        Text("at \(Int(pr.weight)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.primary)
                                    } else if pr.typeString == "dailyVolume" || pr.typeString == "exerciseVolume" {
                                        Text("\(Int(pr.value)) \(UserSettingsManager.shared.weightUnit.rawValue)")
                                            .font(.system(size: 36, weight: .black))
                                            .foregroundColor(.yellow)
                                        Text("Workout Volume")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .frame(width: 220)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                                
                                Button(action: {
                                    onShare(pr)
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share PR Card")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(.systemBackground))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.yellow)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.bottom, 30)
                }
            }
            .scaleEffect(animateScale)
            .opacity(animateOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                animateScale = 1.0
                animateOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateGlow = 1.0
            }
        }
    }
}
