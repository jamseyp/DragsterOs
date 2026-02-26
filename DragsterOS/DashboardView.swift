import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @State private var healthManager = HealthKitManager.shared
    
    var body: some View {
        ScrollView {
            // Your custom UI gauges go here
            Text("Dashboard")
        }
        .task {
            // ✨ THE POLISH: Swift 6 .task modifier automatically handles async cancellation
            // if the user navigates away before the fetch completes.
            do {
                try await healthManager.requestAuthorization()
                
                // Fetch the live telemetry
                let metrics = try await healthManager.fetchMorningReadiness()
                
                // Inject straight into our SwiftData architecture
                let todaysLog = TelemetryLog(
                    date: .now,
                    hrv: metrics.hrv,
                    restingHR: metrics.restingHR,
                    sleepDuration: metrics.sleepHours,
                    weightKG: 0.0, readinessScore: 0.0
                )
                
                context.insert(todaysLog)
                // Note: SwiftData auto-saves, but you can force try? context.save() if needed immediately
                
            } catch {
                print("Telemetry pipeline fault: \(error.localizedDescription)")
            }
        }
    }
}
