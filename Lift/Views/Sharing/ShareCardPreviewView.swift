import SwiftUI

public struct ShareCardPreviewView: View {
    let type: ShareCardType
    let workout: Workout?
    let pr: PersonalRecord?
    let bodyweightEntries: [BodyweightEntry]
    let streakCount: Int
    
    @Environment(\.dismiss) var dismiss
    
    @State private var config = ShareCardConfig()
    @State private var shareImage: UIImage?
    @State private var isSharing = false
    
    public init(
        type: ShareCardType,
        workout: Workout? = nil,
        pr: PersonalRecord? = nil,
        bodyweightEntries: [BodyweightEntry] = [],
        streakCount: Int = 1
    ) {
        self.type = type
        self.workout = workout
        self.pr = pr
        self.bodyweightEntries = bodyweightEntries
        self.streakCount = streakCount
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Title
                    Text("Customize Share Card")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.top, 10)
                    
                    // Card Preview
                    Spacer()
                    
                    MasterShareCardView(
                        type: type,
                        config: config,
                        workout: workout,
                        pr: pr,
                        bodyweightEntries: bodyweightEntries,
                        streakCount: streakCount
                    )
                    .id(configID) // Force redraw when config changes
                    .shadow(color: Color.green.opacity(config.style == .neonLift ? 0.2 : 0), radius: 20)
                    .scaleEffect(config.isSquare ? 0.9 : 0.7) // scale appropriately to fit standard screens
                    .frame(height: config.isSquare ? 360 : 450)
                    
                    Spacer()
                    
                    // Customization Toolbar
                    ScrollView {
                        VStack(spacing: 20) {
                            // Style Select
                            VStack(alignment: .leading, spacing: 8) {
                                Text("STYLE THEME")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                    .tracking(1)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(ShareCardStyle.allCases) { style in
                                            Button(action: {
                                                config.style = style
                                                HapticsService.shared.triggerImpact(style: .light)
                                            }) {
                                                Text(style.rawValue)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(config.style == style ? Color(.systemBackground) : .primary)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(config.style == style ? Color.green : Color(.tertiarySystemBackground))
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Format Select
                            VStack(alignment: .leading, spacing: 8) {
                                Text("FORMAT SIZE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.gray)
                                    .tracking(1)
                                
                                HStack(spacing: 16) {
                                    Button(action: {
                                        config.isSquare = true
                                        HapticsService.shared.triggerImpact(style: .light)
                                    }) {
                                        HStack {
                                            Image(systemName: "square")
                                            Text("Square (1:1)")
                                        }
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(config.isSquare ? Color(.systemBackground) : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(config.isSquare ? Color.green : Color(.tertiarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                    
                                    Button(action: {
                                        config.isSquare = false
                                        HapticsService.shared.triggerImpact(style: .light)
                                    }) {
                                        HStack {
                                            Image(systemName: "rectangle.portrait")
                                            Text("Story (9:16)")
                                        }
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(!config.isSquare ? Color(.systemBackground) : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(!config.isSquare ? Color.green : Color(.tertiarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Toggles
                             VStack(spacing: 12) {
                                Toggle(isOn: $config.showVolume) {
                                    Text("Show Weight Volume")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                Toggle(isOn: $config.showPRs) {
                                    Text("Show PR Badges")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                Toggle(isOn: $config.showWatermark) {
                                    Text("Show Lift Watermark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal)
                            .tint(.green)
                        }
                    }
                    .frame(height: 180)
                    
                    // Share Button
                    Button(action: generateAndShare) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Open Native Share Sheet")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(14)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
            .sheet(isPresented: $isSharing) {
                if let image = shareImage {
                    ActivityViewController(activityItems: [image])
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    // Unique state tracking string to force SwiftUI views to update properly inside ImageRenderer
    private var configID: String {
        "\(config.style.rawValue)_\(config.isSquare)_\(config.showVolume)_\(config.showPRs)_\(config.showWatermark)"
    }
    
    @MainActor
    private func generateAndShare() {
        HapticsService.shared.triggerImpact(style: .medium)
        
        let shareView = MasterShareCardView(
            type: type,
            config: config,
            workout: workout,
            pr: pr,
            bodyweightEntries: bodyweightEntries,
            streakCount: streakCount
        )
        
        if let image = ImageRendererUtility.renderImage(view: shareView) {
            self.shareImage = image
            self.isSharing = true
        }
    }
}

public struct ActivityViewController: UIViewControllerRepresentable {
    public var activityItems: [Any]
    public var applicationActivities: [UIActivity]? = nil
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
