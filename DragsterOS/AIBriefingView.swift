import SwiftUI
import SwiftData

// MARK: - 🧠 AI INTELLIGENCE TERMINAL
struct AIBriefingView: View {
    @Environment(\.modelContext) private var context
    
    // 🗄️ DATA STREAMS
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    @Query(sort: \KineticSession.date, order: .reverse) private var sessions: [KineticSession]
    @Query(sort: \OperationalDirective.date, order: .forward) private var missions: [OperationalDirective]
    
    @State private var healthManager = HealthKitManager.shared
    
    // 🕹️ ASYNC PAYLOAD STATE
    @State private var yesterdayNet: Double = 0
    @State private var hrRecovery: Double = 0
    @State private var respiratoryRate: Double = 0
    @State private var wristTemp: Double = 0
    @State private var sleepArch: (deep: Double, rem: Double, core: Double) = (0,0,0)
    
    @State private var isCompiling = true
    @State private var isCopied = false
    
    // MARK: - 🧠 COMPUTED CONTEXT
    
    private var todayLog: TelemetryLog? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) })
    }
    
    /// Identifies if there is an operational directive scheduled for today
    private var todayMission: OperationalDirective? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return missions.first { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }
    }
    
    private var dynamicCommandStatus: String {
        let readiness = todayLog?.readinessScore ?? 0.0
        let sleep = todayLog?.sleepDuration ?? 0.0
        
        var flags: [String] = []
        
        if readiness >= 80 { flags.append("STATUS: GREEN (OPTIMAL)") }
        else if readiness >= 40 { flags.append("STATUS: YELLOW (DEGRADED)") }
        else { flags.append("STATUS: RED (CRITICAL FATIGUE)") }
        
        if yesterdayNet < -500 { flags.append("WARNING: THERMODYNAMIC DEFICIT") }
        if sleep > 0 && sleep < 6.0 { flags.append("WARNING: INADEQUATE RECOVERY") }
        if respiratoryRate > 18.0 { flags.append("WARNING: ELEVATED RESPIRATION (CNS STRESS)") }
        
        return flags.isEmpty ? "STATUS: NOMINAL" : flags.joined(separator: " | ")
    }
    
    // MARK: - 📦 PAYLOAD CONSTRUCTOR
    
    private var compiledJSONPayload: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let sensorData: [String: Any] = [
            "autonomic_nervous_system": [
                "readiness_score": todayLog?.readinessScore ?? 0,
                "hrv_ms": todayLog?.hrv ?? 0,
                "resting_hr_bpm": todayLog?.restingHR ?? 0,
                "hr_recovery_60sec_bpm": hrRecovery
            ],
            "recovery_biometrics": [
                "sleep_total_hrs": todayLog?.sleepDuration ?? 0,
                "sleep_deep_hrs": sleepArch.deep,
                "sleep_rem_hrs": sleepArch.rem,
                "respiratory_rate": respiratoryRate,
                "wrist_temp_deviation_c": wristTemp
            ],
            "thermodynamics": [
                "yesterday_net_kcal": yesterdayNet,
                "status": yesterdayNet < -500 ? "CRITICAL_DEFICIT" : (yesterdayNet < -50 ? "OPTIMAL_CUT" : "MAINTENANCE")
            ],
            "biomechanics_last_session": [
                "avg_gct_ms": sessions.first?.groundContactTime ?? 0,
                "avg_osc_cm": sessions.first?.verticalOscillation ?? 0
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: sensorData, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "{ \"error\": \"Data compression fault\" }"
    }
    
    private var compiledPayload: String {
        let missionContext = todayMission != nil ? "ACTIVITY: \(todayMission!.activity.uppercased())\nTARGET TSS: \(Int(todayMission!.targetLoad))\nFUEL TIER: \(todayMission!.fuelTier)\nCOACH NOTES: \(todayMission!.coachNotes)" : "NO DIRECTIVE SCHEDULED FOR TODAY. RECOVERY POSTURE RECOMMENDED."
        
        let header = "[SYSTEM: DRAGSTER OS - DIAGNOSTIC EXPORT]\nCOMMAND SYSTEM ASSESSMENT: \(dynamicCommandStatus)\n\n"
        let request = "REQUEST: You are a high-performance tactical AI coach. Provide a concise morning briefing based on the telemetry below. Assess if the chassis is prepared for today's specific directive. Keep the tone clinical, objective, and blunt. Maximum 3 short paragraphs.\n\n"
        let directiveData = "// TODAY'S DIRECTIVE //\n\(missionContext)\n\n"
        let jsonData = "// CLINICAL TELEMETRY JSON //\n\(compiledJSONPayload)"
        
        return header + request + directiveData + jsonData
    }
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // 1. SYSTEM STATUS HEADER
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("INTELLIGENCE PAYLOAD")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.prime)
                        Text(isCompiling ? "GATHERING TELEMETRY..." : "PAYLOAD SECURED")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(isCompiling ? .orange : .green)
                    }
                    Spacer()
                    Image(systemName: "cpu")
                        .font(.system(size: 24))
                        .foregroundStyle(ColorTheme.prime)
                }
                .padding(.horizontal)
                
                if isCompiling {
                    ProgressView().tint(ColorTheme.prime).frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    
                    // 2. HUMAN-READABLE DOSSIER (UX Improvement)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DOSSIER SUMMARY")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            DossierRow(label: "SYSTEM FLAGS", value: dynamicCommandStatus, color: dynamicCommandStatus.contains("RED") || dynamicCommandStatus.contains("WARNING") ? ColorTheme.critical : .green)
                            
                            Divider().background(ColorTheme.surfaceBorder)
                            
                            DossierRow(label: "TODAY'S MISSION", value: todayMission?.activity.uppercased() ?? "REST DAY", color: ColorTheme.prime)
                            
                            if let mission = todayMission {
                                HStack(spacing: 16) {
                                    DossierSubStat(label: "LOAD", value: "\(Int(mission.targetLoad)) TSS")
                                    DossierSubStat(label: "FUEL", value: mission.fuelTier)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. RAW EXPORT (Contained and manageable)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RAW EXPORT STRING")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        TextEditor(text: .constant(compiledPayload))
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(ColorTheme.textPrimary)
                            .frame(height: 150) // Reduced height to keep it out of the way
                            .padding(8)
                            .background(ColorTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ColorTheme.surfaceBorder, lineWidth: 1))
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 4. THE TRANSMIT BUTTON
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        UIPasteboard.general.string = compiledPayload
                        withAnimation { isCopied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isCopied = false }
                        }
                    }) {
                        HStack {
                            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                            Text(isCopied ? "PAYLOAD COPIED" : "COPY TO CLIPBOARD")
                        }
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isCopied ? .green : ColorTheme.prime)
                        .foregroundStyle(ColorTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .padding(.top, 20)
        }
        .applyTacticalOS(title: "AI BRIEFING", showBack: false) // Assuming it's a main tab now
        .task {
            // Concurrent fetching for maximum speed
            async let fuel = healthManager.fetchYesterdayEnergyBalance()
            async let hrr = healthManager.fetchLatestHeartRateRecovery()
            async let resp = healthManager.fetchSleepingRespiratoryRate()
            async let temp = healthManager.fetchWristTemperatureDeviation()
            async let sleep = healthManager.fetchLastNightSleepArchitecture()
            
            let (f, hr, r, t, s) = await (fuel, hrr, resp, temp, sleep)
            
            await MainActor.run {
                self.yesterdayNet = f
                self.hrRecovery = hr
                self.respiratoryRate = r
                self.wristTemp = t
                self.sleepArch = s
                self.isCompiling = false
            }
        }
    }
}

// MARK: - 🧱 SUB-COMPONENTS
struct DossierRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct DossierSubStat: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            Text(value)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(ColorTheme.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ColorTheme.surfaceBorder.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
