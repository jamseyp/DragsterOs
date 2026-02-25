import SwiftUI

// 🎨 ARCHITECTURE: The Dynamic Theme Engine.
// Automatically shifts between "OLED Command" (Dark) and "Track/Alloy" (Light) modes.

struct ColorTheme {
    
    // 🧠 THE ENGINE: Intercepts the iOS trait collection to serve the correct color instantly
    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
    
    // MARK: -  ب Canvas & Structural Colors
    
    // Dark: OLED Black. Light: Tactical Alloy/Off-White
    static let background = dynamicColor(light: UIColor(white: 0.95, alpha: 1.0), dark: .black)
    
    // Dark: Dark Gray. Light: Pure White (for elevated cards)
    static let panel = dynamicColor(light: .white, dark: UIColor(white: 0.12, alpha: 1.0))
    static let panelElevated = dynamicColor(light: UIColor(white: 0.9, alpha: 1.0), dark: UIColor(white: 0.18, alpha: 1.0))
    static let border = dynamicColor(light: UIColor(white: 0.8, alpha: 1.0), dark: UIColor(white: 0.25, alpha: 1.0))
    
    // Glassmorphic Surface Cards
    static let surface = dynamicColor(
        light: UIColor.black.withAlphaComponent(0.04), // Subtle dark shadow on light mode
        dark: UIColor.white.withAlphaComponent(0.05)   // Subtle light glare on dark mode
    )
    static let surfaceBorder = dynamicColor(
        light: UIColor.black.withAlphaComponent(0.1),
        dark: UIColor.white.withAlphaComponent(0.1)
    )
    
    // MARK: - 🖋️ Typography Colors
    
    // Automatically flips from White (Dark Mode) to Black (Light Mode)
    static let textPrimary = dynamicColor(light: .black, dark: .white)
    static let textSecondary = dynamicColor(light: .darkGray, dark: .lightGray)
    static let textMuted = Color.gray
    
    // MARK: - 🏎️ Kinetic Neon Accents
    
    // Accents need to be slightly darker in Light Mode to maintain contrast against white
    static let prime = dynamicColor(light: .systemBlue, dark: .cyan)
    static let warning = dynamicColor(light: .systemOrange, dark: .systemYellow)
    static let critical = Color.red
    static let recovery = dynamicColor(light: .systemGreen, dark: .green)
    static let strategy = Color.purple
    
    // Legacy mapping (to prevent older views from breaking)
    static let optimal = prime
    static let stable = recovery
    static let caution = warning
    static let secondaryData = strategy
    static let primaryBackground = background
    static let cardBackground = panel
    static let warningOrange = Color.orange
    static let accentNeon = dynamicColor(light: UIColor(red: 0.0, green: 0.7, blue: 0.2, alpha: 1.0), dark: UIColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1.0))
    
    // MARK: - 📐 Typography Engine
    
    struct Typography {
        static func dataFont(size: CGFloat) -> Font {
            .system(size: size, weight: .heavy, design: .monospaced)
        }
        static func headerFont(size: CGFloat) -> Font {
            .system(size: size, weight: .black, design: .rounded)
        }
    }
}
