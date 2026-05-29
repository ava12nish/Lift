import SwiftUI

@MainActor
public class ImageRendererUtility {
    /// Renders a SwiftUI view to a high-quality UIImage for social sharing or saving.
    public static func renderImage<V: View>(view: V) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        // Set higher scale for premium, high-resolution rendering
        renderer.scale = 3.0
        return renderer.uiImage
    }
}
