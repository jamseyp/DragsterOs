import SwiftUI
import SwiftData

struct AIBriefingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    @State private var healthManager = HealthKitManager.shared
    
    // Staged Payload Data
    @State private var yesterdayNet: Double = 0
    @State private var isCompiling = true
    
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
        
        return flags.joined(separator: " | ")
    }
    
    // 🧠 THE AI PROMPT CONSTRUCTOR
    private var compiledPayload: String {
        let readiness = todayLog?.readinessScore ?? 0.0
        let hrv = todayLog?.hrv ?? 0.0
        let sleep = todayLog?.sleepDuration ?? 0.0
        
        return """
        [SYSTEM: DRAGSTER OS - DIAGNOSTIC EXPORT]
        COMMAND SYSTEM ASSESSMENT: \(dynamicCommandStatus)
        
        REQUEST: Provide a concise, tactical morning briefing for the Commander based on the telemetry below.
        
        // TELEMETRY DATA //
        READINESS SCORE: \(Int(readiness))/100
        HRV: \(Int(hrv)) ms
        SLEEP: \(String(format: "%.1f", sleep)) hrs
        T-1 THERMODYNAMIC BALANCE: \(Int(yesterdayNet)) kcal
        
        // DIRECTIVE //
        Analyze these factors (Biology, Mechanics, and Fuel). Address the specific flags raised in the COMMAND SYSTEM ASSESSMENT. Keep the tone clinical, objective, and tactical. Maximum 3 paragraphs.
        """
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
                    
                    // 3. THE TRANSMIT BUTTON
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        // Next Step: Trigger API Call here
                        print("📡 Transmitting to Gemini...")
                    }) {
                        HStack {
                            Image(systemName: "waveform")
                            Text("TRANSMIT TO GEMINI AI")
                        }
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.prime)
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
