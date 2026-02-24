import Foundation

// 📐 ARCHITECTURE: The historical data point for the trend chart
struct TelemetrySnapshot: Identifiable {
    let id = UUID()
    let day: String
    let readiness: Int
}
