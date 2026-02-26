import SwiftUI
import SwiftData

struct AIBriefingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    // ✨ FIXED: Added the missing sessions query needed for the JSON blob
    @Query(sort: \KineticSession.date, order: .reverse) private var sessions: [KineticSession]
    
    @State private var healthManager = HealthKitManager.shared
    
    // Staged Payload Data
    @State private var yesterdayNet: Double = 0
    @State private var isCompiling = true
    @State private var isCopied = false // ✨ Feedback state for clipboard
    
    private var todayLog: TelemetryLog? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) })
    }
    
    // 🧠 SYSTEM STATUS LOGIC
    private var dynamicCommandStatus: String {
        let readiness = todayLog?.readinessScore ?? 0.0
        let sleep = todayLog?.sleepDuration ?? 0.0
        
        var flags: [String] = []
        
        // Readiness Vector
        if readiness >= 80 {
            flags.append("STATUS: GREEN (OPTIMAL)")
        } else if readiness >= 40 {
            flags.append("STATUS: YELLOW (DEGRADED)")
        } else {
            flags.append("STATUS: RED (CRITICAL FATIGUE)")
        }
        
        // Fuel Vector
        if yesterdayNet < -500 {
            flags.append("WARNING: THERMODYNAMIC DEFICIT")
        }
        
        // Biological Vector
        if sleep > 0 && sleep < 6.0 {
            flags.append("WARNING: INADEQUATE RECOVERY (SLEEP)")
        }
        
        return flags.isEmpty ? "STATUS: NOMINAL" : flags.joined(separator: " | ")
    }
    
    // 🧠 THE HIGH-RESOLUTION DATA BLOB (JSON)
    private var compiledJSONPayload: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Construct a dictionary of all relevant sensors
        let sensorData: [String: Any] = [
            "readiness_score": todayLog?.readinessScore ?? 0,
            "hrv_ms": todayLog?.hrv ?? 0,
            "resting_hr_bpm": todayLog?.restingHR ?? 0,
            "sleep_hrs": todayLog?.sleepDuration ?? 0,
            "thermodynamics": [
                "yesterday_net_kcal": yesterdayNet,
                "status": yesterdayNet < -500 ? "CRITICAL_DEFICIT" : (yesterdayNet < -50 ? "OPTIMAL_CUT" : "MAINTENANCE")
            ],
            "biomechanics_last_session": [
                "avg_gct_ms": sessions.first?.groundContactTime ?? 0,
                "avg_osc_cm": sessions.first?.verticalOscillation ?? 0,
                "elevation_gain_m": sessions.first?.elevationGain ?? 0
            ]
        ]
        
        // Convert to String for the prompt
        if let data = try? JSONSerialization.data(withJSONObject: sensorData, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "{ \"error\": \"Data compression fault\" }"
    }
    
    // 🧠 THE AI PROMPT CONSTRUCTOR (Refactored to prevent Xcode Hangs)
    private var compiledPayload: String {
        let readiness = todayLog?.readinessScore ?? 0.0
        let hrv = todayLog?.hrv ?? 0.0
        let sleep = todayLog?.sleepDuration ?? 0.0
        
        let header = "[SYSTEM: DRAGSTER OS - DIAGNOSTIC EXPORT]\nCOMMAND SYSTEM ASSESSMENT: \(dynamicCommandStatus)\n\n"
        let request = "REQUEST: Provide a concise, tactical morning briefing for the Commander based on the telemetry below.\n\n"
        let basicData = "// TELEMETRY DATA //\nREADINESS SCORE: \(Int(readiness))/100\nHRV: \(Int(hrv)) ms\nSLEEP: \(String(format: "%.1f", sleep)) hrs\nT-1 THERMODYNAMIC BALANCE: \(Int(yesterdayNet)) kcal\n\n"
        let bioReq = "BioMechanics: Provide a high-resolution, tactical briefing. Analyze the relationship between the Biological pillars and the Biomechanical vectors provided in the JSON blob.\n\n"
        let jsonData = "// TELEMETRY JSON DATA //\n\(compiledJSONPayload)\n\n"
        let directive = "// DIRECTIVE //\nAnalyze these factors (Biology, Mechanics, and Fuel). Address the specific flags raised in the COMMAND SYSTEM ASSESSMENT. Keep the tone clinical, objective, and tactical. Maximum 3 paragraphs."
        
        return header + request + basicData + bioReq + jsonData + directive
    }
    
    var body: some View {
        ScrollView {
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
                    // 2. THE RAW DATA PACKET
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RAW EXPORT STRING")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        TextEditor(text: .constant(compiledPayload))
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(ColorTheme.prime)
                            .frame(height: 250)
                            .padding(8)
                            .background(ColorTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ColorTheme.surfaceBorder, lineWidth: 1)
                            )
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. THE TRANSMIT BUTTON (Clipboard Logic)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        UIPasteboard.general.string = compiledPayload
                        withAnimation { isCopied = true }
                        
                        // Reset status after 2 seconds
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
                }
            }
            .padding(.top, 20)
        }
        .applyTacticalOS(title: "AI BRIEFING", showBack: true)
        .task {
            let fuel = await healthManager.fetchYesterdayEnergyBalance()
            await MainActor.run {
                self.yesterdayNet = fuel
                self.isCompiling = false
            }
        }
    }
}
