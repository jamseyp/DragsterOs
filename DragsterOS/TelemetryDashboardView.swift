import SwiftUI

struct TelemetryDashboardView: View {
    @StateObject var engine = TelemetryManager()
    @Environment(\.dismiss) var dismiss
    
    // ⚙️ THE NEW STATE LAYER
    @State private var showingWeightUpdate = false
    @State private var currentWeight: Double = 96.7
    
    let currentTask = HMTask(
        date: .now,
        activity: "Intervals: 8x600m",
        intensity: "315W - 330W",
        coachNote: "CADENCE REWIRE. 170+ SPM. Do not stomp.",
        fuelTier: "🟡 MED"
    )
    // Add this right under 'let currentTask = ...'
    let weeklyTrendData: [TelemetrySnapshot] = [
        TelemetrySnapshot(day: "MON", readiness: 42),
        TelemetrySnapshot(day: "TUE", readiness: 58),
        TelemetrySnapshot(day: "WED", readiness: 81),
        TelemetrySnapshot(day: "THU", readiness: 64),
        TelemetrySnapshot(day: "FRI", readiness: 72),
        TelemetrySnapshot(day: "SAT", readiness: 88),
        TelemetrySnapshot(day: "SUN", readiness: 92)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. NAVIGATION
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold))
                                Text("DASHBOARD").font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.gray)
                        }
                        Spacer()
                    }.padding(.top, 10)
                    
                    // 2. HEADER
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SYSTEM TELEMETRY")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Rectangle().fill(Color.cyan).frame(width: 40, height: 3)
                    }
                    
                    // 3. THE PERFORMANCE GRID (Now Dynamic!)
                    performanceGrid
                    
                    // 4. DAILY MISSION
                    DailyMissionRow(task: currentTask)
                    
              
                    PerformanceEvolutionCard(data: weeklyTrendData)
                    
                    
                    // 5. SECONDARY SENSORS
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SENSORS & BIOMETRICS")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricCard(title: "RESTING HR", value: "\(engine.currentReport.restingHR) BPM", color: .red)
                            MetricCard(title: "HRV BIAS", value: engine.currentReport.hrvStatus, color: .blue)
                            MetricCard(title: "TOP PACE", value: engine.currentReport.intervalPace, color: .yellow)
                            MetricCard(title: "CADENCE", value: "\(engine.currentReport.averageCadence) SPM", color: .purple)
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarHidden(true)
        // ⚙️ THE NEW ALERT INTERFACE
        .alert("UPDATE CHASSIS MASS", isPresented: $showingWeightUpdate) {
            TextField("Weight (kg)", value: $currentWeight, format: .number)
                .keyboardType(.decimalPad)
            Button("CANCEL", role: .cancel) { }
            Button("UPDATE ENGINE") { hapticImpact(.medium) }
        } message: {
            Text("Enter morning weight to recalibrate Power-to-Weight efficiency.")
        }
    }
    
    // 📐 THE BALANCED GRID LOGIC
    private var performanceGrid: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: Efficiency Card (Now wired to state!)
            EfficiencyCoefficientCard(
                ratio: PerformanceEngine.calculatePowerToWeight(power: Double(engine.currentReport.maxPower), weight: currentWeight),
                weight: currentWeight,
                watts: engine.currentReport.maxPower,
                onUpdateTap: {
                    hapticImpact(.light) // Tactile feedback on tap
                    showingWeightUpdate = true
                }
            )
            .frame(maxWidth: .infinity)
            
            // Right: Numeric Readiness Card
            ReadinessMetricCard(score: Int(engine.currentReport.readinessScore))
                .frame(maxWidth: .infinity)
        }
    }
    
    // ⚙️ THE HAPTIC ENGINE
    private func hapticImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
