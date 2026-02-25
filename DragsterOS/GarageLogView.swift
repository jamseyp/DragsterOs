import SwiftUI
import SwiftData

// 📐 ARCHITECTURE: The routing view. It finds today's specific telemetry log
// and safely injects it into the editing canvas via @Bindable.
struct GarageLogView: View {
    // Fetch all logs, newest first
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    // Dynamically find today's log to edit
    private var todayLog: TelemetryLog? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) })
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let log = todayLog {
                KineticEntryCanvas(log: log)
            } else {
                // Fallback if the HealthKit pipeline hasn't fired yet
                ContentUnavailableView(
                    "AWAITING SENSOR LINK",
                    systemImage: "waveform.path.ecg",
                    description: Text("Return to the Command Center to initialize today's telemetry.")
                )
                .foregroundStyle(.cyan)
            }
        }
        .navigationTitle("KINETIC OUTPUT")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// 🎨 THE CANVAS: The tactile data-entry interface.
struct KineticEntryCanvas: View {
    // ✨ THE POLISH: @Bindable creates a direct, real-time pipeline to the database.
    @Bindable var log: TelemetryLog
    
    // Local state for the text field to prevent binding lag
    @State private var intervalPaceText: String = ""
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                
                // 1. NEUROMUSCULAR FATIGUE (Soreness)
                VStack(alignment: .leading, spacing: 8) {
                    Label("SUBJECTIVE SORENESS", systemImage: "figure.run")
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(.gray)
                    
                    HStack {
                        Text("FRESH")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.green)
                        
                        // A fluid slider mapped 1 to 10
                        Slider(value: $log.subjectiveSoreness, in: 1...10, step: 1) { _ in
                            triggerHapticClick()
                        }
                        .tint(log.subjectiveSoreness > 7 ? .red : .cyan)
                        
                        Text("DESTROYED")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.red)
                    }
                    
                    Text("\(Int(log.subjectiveSoreness)) / 10")
                        .font(.system(.title2, design: .monospaced, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // 2. KINETIC METRICS (Power & Cadence)
                HStack(spacing: 16) {
                    // Max Power Controller
                    MetricDialCard(
                        title: "PEAK WATTS",
                        value: Binding(
                            get: { log.maxPower ?? 0.0 },
                            set: { log.maxPower = $0 }
                        ),
                        unit: "W",
                        step: 5.0,
                        color: .purple
                    )
                    
                    // Cadence Controller
                    MetricDialCard(
                        title: "AVG CADENCE",
                        value: Binding(
                            get: { log.avgCadence ?? 0.0 },
                            set: { log.avgCadence = $0 }
                        ),
                        unit: "SPM",
                        step: 1.0,
                        color: .cyan
                    )
                }
                
                // 3. INTERVAL PACE ENTRY
                VStack(alignment: .leading, spacing: 8) {
                    Label("TARGET INTERVAL PACE", systemImage: "stopwatch.fill")
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(.gray)
                    
                    TextField("e.g. 4:50/km", text: $intervalPaceText)
                        .keyboardType(.numbersAndPunctuation)
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(.cyan)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: intervalPaceText) { _, newValue in
                            log.intervalPace = newValue
                        }
                        .onAppear {
                            intervalPaceText = log.intervalPace ?? ""
                        }
                }
            }
            .padding()
        }
    }
    
    // Mechanical feedback for physical data entry
    private func triggerHapticClick() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// ✨ THE POLISH: A reusable, highly-stylized stepper card for numerical data
struct MetricDialCard: View {
    var title: String
    @Binding var value: Double
    var unit: String
    var step: Double
    var color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.gray)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(value))")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText()) // Smooth roll animation
                Text(unit)
                    .font(.caption2.bold())
                    .foregroundStyle(color)
            }
            
            // Custom Stepper Controls
            HStack(spacing: 20) {
                Button(action: { decrement() }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray.opacity(0.5))
                }
                
                Button(action: { increment() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(color)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func increment() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            value += step
        }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    
    private func decrement() {
        if value > 0 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                value -= step
            }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
}
