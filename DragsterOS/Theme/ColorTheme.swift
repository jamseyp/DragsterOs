// ColorTheme.swift
import SwiftUI

struct ColorTheme {
    // Canvas Colors
    static let background = Color.black
    static let panel = Color(white: 0.12) // Slightly elevated for cards
    static let panelElevated = Color(white: 0.18) // For pressed states or highlights
    static let border = Color(white: 0.25)
    
    // Typography Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    
    // Telemetry Accent Colors
    static let optimal = Color.cyan
    static let stable = Color.green
    static let caution = Color.orange
    static let warning = Color.yellow
    static let critical = Color.red
    static let secondaryData = Color.purple
    
    static let primaryBackground = Color.black
        static let cardBackground = Color(white: 0.07)
        static let accentNeon = Color(red: 0.2, green: 1.0, blue: 0.4) // Neon Green
        static let warningOrange = Color.orange
    
    struct Typography {
            static func dataFont(size: CGFloat) -> Font {
                .system(size: size, weight: .heavy, design: .monospaced)
            }
            static func headerFont(size: CGFloat) -> Font {
                .system(size: size, weight: .black, design: .rounded)
            }
        }
}
