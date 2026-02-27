import SwiftUI
import SwiftData
import Charts

// MARK: - 🧬 BIOMETRIC BASELINE COMMAND
/// This terminal acts as the primary health and recovery diagnostic screen.
/// It aggregates Apple Health data to provide a macro-level view of cardiovascular fitness,
/// autonomic nervous system recovery, sleep architecture, and physical composition.
struct BiometricBaselineView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Environment(\.modelContext) private var context
    
    /// Pulls the entire historical telemetry cache, sorted newest to oldest.
    /// This array is used to compute 7-day rolling baselines for trend analysis.
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    // MARK: - 🕹️ STATE MANAGEMENT
    @State private var healthManager = HealthKitManager.shared
    
    // Core Composition & Capacity State
    @State private var vo2Max: Double = 0
    @State private var bodyFat: Double = 0
    @State private var leanMass: Double = 0
    
    // Advanced Recovery State
    @State private var hrRecovery: Double = 0
    @State private var respiratoryRate: Double = 0
    @State private var wristTemp: Double = 0
    @State private var sleepDeep: Double = 0
    @State private var sleepREM: Double = 0
    
    // Controls the loading spinner while the async fetch operates
    @State private var isLoading = true

    // MARK: - 🧠 COMPUTED BASELINES
    /// Extracts the most recent log to grab today's total body weight.
    private var latestLog: TelemetryLog? { logs.first }
    
    /// Slices the first 7 entries to establish the current week's trajectory.
    private var recentLogs: [TelemetryLog] { Array(logs.prefix(7)) }
    
    /// Calculates the 7-day rolling average for HRV.
    /// Includes a guard to prevent division by zero if the database is empty.
    private var avgHRV: Int {
        guard !recentLogs.isEmpty else { return 0 }
        return Int(recentLogs.map { $0.hrv }.reduce(0, +) / Double(recentLogs.count))
    }
    
    /// Calculates the 7-day rolling average for Resting Heart Rate.
    private var avgRHR: Int {
        guard !recentLogs.isEmpty else { return 0 }
        return Int(recentLogs.map { $0.restingHR }.reduce(0, +) / Double(recentLogs.count))
    }

    // MARK: - 🖼️ UI BODY
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // ---------------------------------------------------------
                // 1. AEROBIC CAPACITY (VO2 MAX)
                // ---------------------------------------------------------
                // Strategic Purpose: Defines the absolute ceiling of the cardiovascular system.
                // Placed at the top as it is the primary indicator of endurance potential.
                VStack(spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AEROBIC CAPACITY (VO2 MAX)")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            
                            if isLoading {
                                ProgressView().tint(ColorTheme.prime)
                            } else {
                                Text(vo2Max > 0 ? String(format: "%.1f", vo2Max) : "--")
                                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                                    .foregroundStyle(ColorTheme.prime)
                            }
                        }
                        Spacer()
                        // Categorical mapping (Elite, Superior, etc.) based on standard clinical tables
                        if !isLoading && vo2Max > 0 {
                            VO2MaxBadge(score: vo2Max)
                        }
                    }
                    
                    // Visual Gauge: Maps current VO2 Max against an assumed human ceiling of ~65-70.
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(ColorTheme.background)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [ColorTheme.prime.opacity(0.5), ColorTheme.prime], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * min(vo2Max / 65.0, 1.0))
                        }
                    }
                    .frame(height: 8)
                }
                .padding(20)
                .background(ColorTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // ---------------------------------------------------------
                // 2. AUTONOMIC NERVOUS SYSTEM (ANS) TRENDS
                // ---------------------------------------------------------
                // Strategic Purpose: Tracks the balance between sympathetic (fight/flight)
                // and parasympathetic (rest/digest) nervous systems over a 7-day macro cycle.
                VStack(spacing: 16) {
                    HStack {
                        Text("7-DAY ANS TRENDS")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        Spacer()
                    }
                    
                    if recentLogs.count > 1 {
                        HStack(spacing: 12) {
                            // Uses KeyPaths (\.hrv) to dynamically map data into the reusable TrendCard
                            TrendCard(title: "HRV BASELINE", value: avgHRV, unit: "MS", color: .cyan, logs: recentLogs, dataKeyPath: \.hrv)
                            TrendCard(title: "RHR BASELINE", value: avgRHR, unit: "BPM", color: ColorTheme.critical, logs: recentLogs, dataKeyPath: \.restingHR)
                        }
                    } else {
                        // Failsafe UI if a new user has less than 2 days of data logged
                        Text("INSUFFICIENT DATA FOR TREND ANALYSIS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // ---------------------------------------------------------
                // 3. ADVANCED RECOVERY DIAGNOSTICS
                // ---------------------------------------------------------
                // Strategic Purpose: Aggregates secondary biometric markers that act as
                // early-warning systems for systemic fatigue, illness, or incomplete cellular repair.
                VStack(alignment: .leading, spacing: 20) {
                    Text("ADVANCED RECOVERY DIAGNOSTICS")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                    
                    if isLoading {
                        ProgressView().tint(ColorTheme.prime).frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // Sub-Section: Sleep Architecture
                        // Measures actual repair time (Deep) vs cognitive clearing (REM)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SLEEP ARCHITECTURE (LAST NIGHT)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(ColorTheme.prime)
                            
                            HStack(spacing: 16) {
                                SleepPhaseCard(phase: "DEEP (CHASSIS REPAIR)", hours: sleepDeep, color: .purple)
                                SleepPhaseCard(phase: "REM (CNS RECOVERY)", hours: sleepREM, color: .cyan)
                            }
                        }
                        
                        Divider().background(ColorTheme.surfaceBorder)
                        
                        // Sub-Section: Autonomic & Inflammatory Markers
                        VStack(spacing: 12) {
                            DiagnosticRow(
                                label: "HR RECOVERY (60 SEC)",
                                value: hrRecovery > 0 ? "-\(Int(hrRecovery))" : "--",
                                unit: "BPM"
                            )
                            DiagnosticRow(
                                label: "RESPIRATORY RATE",
                                value: respiratoryRate > 0 ? String(format: "%.1f", respiratoryRate) : "--",
                                unit: "BR/MIN"
                            )
                            DiagnosticRow(
                                label: "WRIST TEMP DEVIATION",
                                value: wristTemp != 0 ? String(format: "%+.2f", wristTemp) : "--",
                                unit: "°C"
                            )
                        }
                    }
                }
                .padding(20)
                .background(ColorTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // ---------------------------------------------------------
                // 4. CHASSIS COMPOSITION TERMINAL
                // ---------------------------------------------------------
                // Strategic Purpose: Breaks down gross body weight into functional
                // (lean mass) and non-functional (fat) components.
                VStack(alignment: .leading, spacing: 20) {
                    Text("CHASSIS COMPOSITION")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                    
                    if isLoading {
                        ProgressView().tint(ColorTheme.prime).frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        HStack(spacing: 24) {
                            CompositionCircle(label: "BODY FAT", value: bodyFat, unit: "%", color: .orange)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                CompositionRow(label: "TOTAL MASS", value: latestLog?.weightKG ?? 0, unit: "KG")
                                Divider().background(ColorTheme.surfaceBorder)
                                CompositionRow(label: "LEAN MASS", value: leanMass, unit: "KG")
                            }
                        }
                    }
                }
                .padding(20)
                .background(ColorTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Footer Disclaimer
                Text("DATA SOURCE: DIRECT APPLE HEALTH INGESTION. ALL METRICS CALCULATED ON A 7-DAY ROLLING WINDOW.")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .applyTacticalOS(title: "SYSTEM BASELINES", showBack: true)
        .task {
            // Trigger background data aggregation immediately on view load
            await fetchBaselines()
        }
    }

    // MARK: - ⚙️ DATA AGGREGATION ENGINE
    /// Fetches the latest objective biometrics concurrently from Apple Health,
    /// performs local mathematical derivations (e.g., Lean Mass), and forces UI updates on the Main Actor.
    private func fetchBaselines() async {
        let vo2 = await healthManager.fetchLatestVO2Max()
        let fat = await healthManager.fetchLatestBodyFat()
        let hrr = await healthManager.fetchLatestHeartRateRecovery()
        let respRate = await healthManager.fetchSleepingRespiratoryRate()
        let tempDev = await healthManager.fetchWristTemperatureDeviation()
        let sleepArch = await healthManager.fetchLastNightSleepArchitecture()
        
        await MainActor.run {
            self.vo2Max = vo2
            self.bodyFat = fat
            self.hrRecovery = hrr
            self.respiratoryRate = respRate
            self.wristTemp = tempDev
            self.sleepDeep = sleepArch.deep
            self.sleepREM = sleepArch.rem
            
            // Derive Lean Mass: If chassis is 100kg and 15% fat, Lean Mass is 85kg.
            if let weight = latestLog?.weightKG, bodyFat > 0 {
                self.leanMass = weight * (1 - (bodyFat / 100))
            }
            self.isLoading = false
        }
    }
}

// MARK: - 🧱 SUB-COMPONENTS

/// Evaluates absolute VO2 Max against general population data to return a string/color categorization.
struct VO2MaxBadge: View {
    let score: Double
    var category: (text: String, color: Color) {
        if score >= 55 { return ("ELITE", ColorTheme.prime) }
        if score >= 48 { return ("SUPERIOR", .green) }
        if score >= 42 { return ("GOOD", .cyan) }
        return ("FAIR", .orange)
    }
    
    var body: some View {
        Text(category.text)
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(category.color.opacity(0.15))
            .foregroundStyle(category.color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(category.color.opacity(0.5), lineWidth: 1))
    }
}

/// A scalable card component that takes a dynamic data keypath to generate a 7-day sparkline chart.
struct TrendCard: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    let logs: [TelemetryLog]
    let dataKeyPath: KeyPath<TelemetryLog, Double>
    
    // Reverse the logs so the chart draws chronologically (left = oldest, right = newest)
    private var chronologicalLogs: [TelemetryLog] {
        logs.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
            }
            
            // Native Swift Chart: Renders the historical trend
            Chart(chronologicalLogs) { log in
                LineMark(
                    x: .value("Date", log.date),
                    y: .value("Value", log[keyPath: dataKeyPath])
                )
                .interpolationMethod(.catmullRom) // Catmull-Rom ensures curved, flowing lines rather than rigid spikes
                .foregroundStyle(color)
                
                // Provides a fading gradient below the line for a robust, glowing aesthetic
                AreaMark(
                    x: .value("Date", log.date),
                    yStart: .value("Min", chronologicalLogs.map{ $0[keyPath: dataKeyPath] }.min() ?? 0 * 0.9),
                    yEnd: .value("Value", log[keyPath: dataKeyPath])
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(colors: [color.opacity(0.3), Color.clear], startPoint: .top, endPoint: .bottom))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 40)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTheme.surfaceBorder.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Specialized UI card for displaying hours and minutes of specific sleep stages.
struct SleepPhaseCard: View {
    let phase: String
    let hours: Double
    let color: Color
    
    // Converts decimal hours (e.g., 1.5) into tactical readability (e.g., 1H 30M)
    private var formattedTime: String {
        if hours == 0 { return "--" }
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)H \(m)M"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(phase)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            
            Text(formattedTime)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(ColorTheme.surfaceBorder.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Generic row for single-line diagnostic outputs (e.g., Temperature, Respiration).
struct DiagnosticRow: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(ColorTheme.textPrimary)
            Text(unit)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
        }
    }
}

/// Generic row specifically formatted for weight and mass components.
struct CompositionRow: View {
    let label: String
    let value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            Spacer()
            Text(value > 0 ? String(format: "%.1f", value) : "--")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(ColorTheme.textPrimary)
            Text(unit)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
        }
    }
}

/// Circular gauge to visually depict a percentage metric (Body Fat).
struct CompositionCircle: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        ZStack {
            // Static background track
            Circle().stroke(ColorTheme.background, lineWidth: 8)
            
            // Dynamic value overlay, rotated -90 degrees to start at the 12 o'clock position
            Circle().trim(from: 0, to: CGFloat(value / 100))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text(value > 0 ? String(format: "%.1f", value) : "--")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
                Text(unit)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
            }
        }
        .frame(width: 90, height: 90)
    }
}
