import SwiftUI
import SwiftData

// MARK: - 🔍 VIEW: DETAIL CANVAS (VECTOR EDITION)
struct SessionDetailCanvas: View {
    let session: KineticSession
    
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    // ✨ MISSION COMPLIANCE LINK
    @Query private var allDirectives: [OperationalDirective]
    
    @Environment(\.dismiss) private var dismiss
    
    // ✨ JIT Data Arrays for Charts
    private let healthManager = HealthKitManager.shared // FIXED: No @State
    
    @State private var hrArray: [(Date, Double)] = []
    @State private var powerArray: [(Date, Double)] = []
    @State private var cadenceArray: [(Date, Double)] = []
    @State private var isLoadingVectors = true
    @State private var gctSeries: [(Date, Double)] = []
    @State private var oscillationSeries: [(Date, Double)] = []
    
    // ✨ COMPUTED PROPERTY TO GRAB THE ACTUAL MISSION OBJECT
    private var matchedDirective: OperationalDirective? {
        allDirectives.first { $0.id == session.linkedDirectiveID }
    }
    
    // MARK: - 🧠 AEROBIC DECOUPLING ENGINE
    private var aerobicDecoupling: Double? {
        guard hrArray.count > 20, powerArray.count > 20 else { return nil }
        
        let sortedHR = hrArray.sorted { $0.0 < $1.0 }
        let sortedPower = powerArray.sorted { $0.0 < $1.0 }
        
        let midHR = sortedHR.count / 2
        let midPower = sortedPower.count / 2
        
        let hrFirstHalf = sortedHR[0..<midHR].map { $0.1 }.reduce(0, +) / Double(midHR)
        let hrSecondHalf = sortedHR[midHR...].map { $0.1 }.reduce(0, +) / Double(sortedHR.count - midHR)
        
        let pwrFirstHalf = sortedPower[0..<midPower].map { $0.1 }.reduce(0, +) / Double(midPower)
        let pwrSecondHalf = sortedPower[midPower...].map { $0.1 }.reduce(0, +) / Double(sortedPower.count - midPower)
        
        guard hrFirstHalf > 0, hrSecondHalf > 0 else { return nil }
        
        let efFirstHalf = pwrFirstHalf / hrFirstHalf
        let efSecondHalf = pwrSecondHalf / hrSecondHalf
        
        return ((efFirstHalf - efSecondHalf) / efFirstHalf) * 100.0
    }
    
    private var morningReadiness: Int? {
        let log = logs.first { Calendar.current.isDate($0.date, inSameDayAs: session.date) }
        return log != nil ? Int(log!.readinessScore) : nil
    }
    
    private var performanceMetric: (value: String, unit: String) {
        if session.distanceKM <= 0 { return ("-", "N/A") }
        if session.discipline == "SPIN" {
            let speed = session.distanceKM / (session.durationMinutes / 60.0)
            return (String(format: "%.1f", speed), "KM/H")
        } else {
            let pace = session.durationMinutes / session.distanceKM
            let mins = Int(pace), secs = Int((pace - Double(mins)) * 60)
            return (String(format: "%d:%02d", mins, secs), "/KM")
        }
    }
    
    // MARK: 🧠 HR ZONE ENGINE
    private var hrZones: [(zone: String, time: Double, color: Color)] {
        guard !hrArray.isEmpty else { return [] }
        
        var z1 = 0.0, z2 = 0.0, z3 = 0.0, z4 = 0.0, z5 = 0.0
        let sorted = hrArray.sorted { $0.0 < $1.0 }
        
        for i in 0..<(sorted.count - 1) {
            let bpm = sorted[i].1
            let duration = sorted[i+1].0.timeIntervalSince(sorted[i].0)
            let validDuration = min(duration, 10.0)
            
            switch bpm {
            case ..<133: z1 += validDuration
            case 133..<152: z2 += validDuration
            case 152..<171: z3 += validDuration
            case 171..<185: z4 += validDuration
            default: z5 += validDuration
            }
        }
        
        return [
            ("Z1", z1 / 60.0, .gray),
            ("Z2", z2 / 60.0, .cyan),
            ("Z3", z3 / 60.0, .green),
            ("Z4", z4 / 60.0, .orange),
            ("Z5", z5 / 60.0, ColorTheme.critical)
        ].filter { $0.1 > 0 }
    }
    
    // MARK: - 📤 HIGH-RESOLUTION JSON GENERATOR
    private func generateHighResJSONPayload() -> String {
        // Strip timestamps and convert to raw value arrays to prevent AI context overload
        let hrVector = hrArray.map { Int($0.1) }
        let pwrVector = powerArray.map { Int($0.1) }
        let cadVector = cadenceArray.map { Int($0.1) }
        let gctVector = gctSeries.map { Int($0.1) }
        let oscVector = oscillationSeries.map { Double(String(format: "%.1f", $0.1)) ?? 0.0 }
        
        let payloadDict: [String: Any] = [
            "session_metadata": [
                "discipline": session.discipline,
                "duration_minutes": session.durationMinutes,
                "distance_km": session.distanceKM,
                "rpe": session.rpe,
                "morning_readiness_score": morningReadiness ?? 0,
                // Removed chassis_equipment per previous purge
            ],
            "scalar_averages": [
                "avg_hr": Int(session.averageHR),
                "avg_power": session.avgPower != nil ? Int(session.avgPower!) : 0,
                "avg_cadence": session.avgCadence != nil ? Int(session.avgCadence!) : 0,
                "avg_gct_ms": session.groundContactTime != nil ? Int(session.groundContactTime!) : 0,
                "avg_osc_cm": session.verticalOscillation ?? 0,
                "aerobic_decoupling_pct": aerobicDecoupling ?? 0
            ],
            "vector_time_series": [
                "hr_bpm_array": hrVector,
                "power_w_array": pwrVector,
                "cadence_spm_array": cadVector,
                "gct_ms_array": gctVector,
                "oscillation_cm_array": oscVector
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: payloadDict, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            
            // ✨ FIXED: Added matchedDirective handling
            let missionTitle = matchedDirective?.activity ?? "FREE RUN (NO DIRECTIVE)"
            let missionGoal = matchedDirective?.powerTarget ?? "N/A"
            
            return """
            [SYSTEM: DRAGSTER OS - HIGH-RES SESSION EXPORT]
            ---
            INSTRUCTION TO AI COACH: 
            Perform a Bio-Kinetic Diagnostic for the current training phase (10k/HM).

            1. DIRECTIVE COMPLIANCE: Compare this session against the [MISSION CONTEXT] block. Did the athlete execute the prescribed intensity, or was there "Executive Over-reach"?
            2. ENGINE EFFICIENCY: Analyze the Efficiency Factor (EF: Power/HR). Is the cardiovascular engine becoming more economical at this specific intensity?
            3. MECHANICAL DURABILITY: Compare early-session Biomechanics (GCT/Oscillation) against late-session telemetry. Identify any "wattage leaks" or structural breakdown indicative of fatigue for a 95kg chassis.
            4. ADAPTATION STATUS: Cross-reference this session's mechanical load against the Morning Readiness Score (Elite HRV).
            ---
            
            MISSION CONTEXT:
            - PLANNED: \(missionTitle)
            - GOAL: \(missionGoal)
            - ACTUAL: \(Int(session.avgPower ?? 0))W @ \(Int(session.averageHR)) BPM
            
            REQUEST: Perform a deep tactical analysis of this session's mechanical and biological vectors.
            
            // TELEMETRY JSON //
            \(jsonString)
            
            // DIRECTIVE //
            1. Analyze the `vector_time_series` arrays for correlation. Does Form (GCT/Oscillation) degrade as HR spikes or toward the end of the arrays?
            2. Evaluate the `aerobic_decoupling_pct`. If > 5%, address endurance drift.
            3. Provide a clinical, objective summary of the Commander's mechanical efficiency.
            """
        }
        
        return "ERROR: COMPRESSION FAULT"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // 1. ✨ AI EXPORT PIPELINE (UPDATED FOR JSON)
                Button(action: {
                    let exportPayload = generateHighResJSONPayload()
                    UIPasteboard.general.string = exportPayload
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }) {
                    Label("EXPORT FULL TELEMETRY TO GEMINI", systemImage: "brain.head.profile")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.background)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ColorTheme.prime)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // ✨ 2. THE MISSION COMPLIANCE BANNER
                if let mission = matchedDirective {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ASSIGNED MISSION")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.prime)
                        Text(mission.activity.uppercased())
                            .font(.system(size: 18, weight: .black, design: .rounded))
                        Text("GOAL: \(mission.powerTarget)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.prime.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal)
                }
                
                // 3. HERO METRICS
                VStack(spacing: 8) {
                    Image(systemName: session.disciplineIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(session.disciplineColor)
                    Text(session.distanceKM > 0 ? "\(session.distanceKM, specifier: "%.2f") KM" : "\(Int(session.durationMinutes)) MIN")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                // 4. SCALAR GRID: KINETICS
                HStack(spacing: 12) {
                    TelemetryBlock(title: "AVG POWER", value: session.avgPower != nil ? "\(Int(session.avgPower!))" : "-", unit: "W")
                    TelemetryBlock(title: "CADENCE", value: session.avgCadence != nil ? "\(Int(session.avgCadence!))" : "-", unit: "SPM")
                    TelemetryBlock(title: "PACE/SPD", value: performanceMetric.value, unit: performanceMetric.unit)
                }
                .padding(.horizontal)
                
                // 5. SCALAR GRID: ADVANCED BIOMECHANICS
                if session.groundContactTime != nil || session.verticalOscillation != nil || session.elevationGain != nil {
                    HStack(spacing: 12) {
                        if let gct = session.groundContactTime {
                            TelemetryBlock(title: "GCT", value: "\(Int(gct))", unit: "MS")
                        }
                        if let osc = session.verticalOscillation {
                            TelemetryBlock(title: "OSCILLATION", value: String(format: "%.1f", osc), unit: "CM")
                        }
                        if let elev = session.elevationGain {
                            TelemetryBlock(title: "ELEVATION", value: "\(Int(elev))", unit: "M")
                        }
                    }
                    .padding(.horizontal)
                }

                // 6. SCALAR GRID: BIOMETRICS
                HStack(spacing: 12) {
                    TelemetryBlock(title: "READINESS", value: morningReadiness != nil ? "\(morningReadiness!)" : "-", unit: "/100")
                    TelemetryBlock(title: "AVG HR", value: "\(Int(session.averageHR))", unit: "BPM")
                    TelemetryBlock(title: "EFFORT", value: "\(session.rpe)", unit: "/10")
                }
                .padding(.horizontal)
                
                // 7. VECTOR CHARTS (JIT Rendered)
                VStack(spacing: 16) {
                    if isLoadingVectors {
                        ProgressView().tint(ColorTheme.prime).padding(.vertical, 40)
                    } else {
                        if !hrArray.isEmpty {
                            TelemetryChartCard(title: "HEART RATE VECTOR", icon: "heart.fill", data: hrArray, color: ColorTheme.critical, unit: "BPM")
                        }
                        if !powerArray.isEmpty {
                            TelemetryChartCard(title: "MECHANICAL POWER", icon: "bolt.fill", data: powerArray, color: .orange, unit: "W")
                        }
                        if !cadenceArray.isEmpty {
                            TelemetryChartCard(title: "CADENCE SPARKLINE", icon: "arrow.triangle.2.circlepath", data: cadenceArray, color: .cyan, unit: "SPM")
                        }
                        if !gctSeries.isEmpty {
                            TelemetryChartCard(title: "GCT", icon: "footprint.fill", data: gctSeries, color: .blue, unit:"MS") // Fixed unit to MS
                        }
                        if !oscillationSeries.isEmpty {
                            TelemetryChartCard(title: "Vertical Oscillation", icon: "arrow.up.and.down.and.sparkles", data: oscillationSeries, color: .yellow, unit: "CM")
                        }
                        
                        // AEROBIC DECOUPLING METRIC
                        if let decoupling = aerobicDecoupling {
                            let isEfficient = decoupling <= 5.0
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("AEROBIC DECOUPLING (Pa:Hr)")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textMuted)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", decoupling))
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundStyle(isEfficient ? .green : ColorTheme.critical)
                                    
                                    Text("%")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                        .foregroundStyle(isEfficient ? .green : ColorTheme.critical)
                                    
                                    Spacer()
                                    
                                    Image(systemName: isEfficient ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(isEfficient ? .green : ColorTheme.critical)
                                }
                                
                                Text(isEfficient
                                     ? "Optimal aerobic efficiency maintained. Cardiovascular drift was kept under the 5% threshold."
                                     : "Cardiovascular drift detected. Your base endurance is currently lacking for this specific duration/intensity.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(ColorTheme.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("⚠️ METRIC ONLY VALID FOR STEADY-STATE / ZONE 2 EFFORTS. IGNORE FOR INTERVALS.")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundStyle(ColorTheme.warning)
                                    .padding(.top, 4)
                            }
                            .padding(20)
                            .background(ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // TIME IN ZONES
                        if !hrZones.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TIME IN ZONES").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
                                
                                HStack(spacing: 4) {
                                    ForEach(hrZones, id: \.zone) { zone in
                                        VStack(spacing: 4) {
                                            Text("\(Int(zone.time))m")
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                .foregroundStyle(ColorTheme.textPrimary)
                                            
                                            Rectangle()
                                                .fill(zone.color)
                                                .frame(height: 6)
                                                .clipShape(Capsule())
                                            
                                            Text(zone.zone)
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundStyle(ColorTheme.textMuted)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal)
                
                // 8. ATHLETE NOTES
                if !session.coachNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ATHLETE NOTES").font(.system(size: 12, weight: .black, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
                        Text(session.coachNotes).foregroundStyle(ColorTheme.textPrimary).italic()
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading).background(ColorTheme.surface).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .applyTacticalOS(title: "DIRECTIVE ANALYSIS")
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ColorTheme.prime)
                    .padding()
            }
        }
        .task {
            let isRide = session.discipline == "SPIN"
            async let fetchedHR = healthManager.fetchHRSeries(start: session.date, durationMinutes: session.durationMinutes)
            async let fetchedPower = healthManager.fetchPowerSeries(start: session.date, durationMinutes: session.durationMinutes, isRide: isRide)
            async let fetchedCadence = healthManager.fetchCadenceSeries(start: session.date, durationMinutes: session.durationMinutes, isRide: isRide)
            async let gctData = healthManager.fetchGCTSeries(start: session.date, durationMinutes: session.durationMinutes)
            async let oscData = healthManager.fetchOscillationSeries(start: session.date, durationMinutes: session.durationMinutes)
            
            let (hrRes, pwrRes, cadRes, gct, osc) = await (fetchedHR, fetchedPower, fetchedCadence, gctData, oscData)
            
            await MainActor.run {
                self.hrArray = hrRes
                self.powerArray = pwrRes
                self.cadenceArray = cadRes
                self.gctSeries = gct
                self.oscillationSeries = osc
                self.isLoadingVectors = false
            }
        }
    }
}
