import SwiftUI
import SwiftData

// MARK: - 🧠 AI INTELLIGENCE TERMINAL
struct AIBriefingView: View {
    @Environment(\.modelContext) private var context
    
    // 🗄️ DATA STREAMS
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    @Query(sort: \KineticSession.date, order: .reverse) private var sessions: [KineticSession]
    @Query(sort: \OperationalDirective.assignedDate, order: .forward) private var missions: [OperationalDirective]
    
    // ✨ NEW STREAMS: Registry and Objectives
    @Query private var registries: [UserRegistry]
    @Query(sort: \StrategicObjective.targetDate, order: .forward) private var fetchedObjectives: [StrategicObjective]
    
    @State private var healthManager = HealthKitManager.shared
    @State private var showingRegistry = false
    
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
    
    private var todayMission: OperationalDirective? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return missions.first { Calendar.current.isDate($0.assignedDate, inSameDayAs: startOfDay) }
    }
    
    private var dynamicCommandStatus: String {
        let readiness = todayLog?.readinessScore ?? 0.0
        let sleep = todayLog?.sleepDuration ?? 0.0
        
        var flags: [String] = []
        
        if readiness >= 80 { flags.append("Status: Green (Optimal)") }
        else if readiness >= 40 { flags.append("Status: Yellow (Degraded)") }
        else { flags.append("Status: Red (Critical Fatigue)") }
        
        if yesterdayNet < -500 { flags.append("Warning: Thermodynamic Deficit") }
        if sleep > 0 && sleep < 6.0 { flags.append("Warning: Inadequate Recovery") }
        if respiratoryRate > 18.0 { flags.append("Warning: Elevated Respiration (CNS Stress)") }
        
        return flags.isEmpty ? "Status: Nominal" : flags.joined(separator: " | ")
    }
    
    // MARK: - 📦 PAYLOAD CONSTRUCTOR
    
    private var compiledJSONPayload: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let registry = registries.first ?? UserRegistry()
        
        let sensorData: [String: Any] = [
            "user_baselines": [
                "target_weight_kg": registry.targetWeight, // ✨ INJECTED: Core metric for coach logic
                "max_hr_bpm": registry.maxHR,
                "resting_hr_bpm": registry.restingHR,
                "vo2_max": registry.vo2Max,
                "z2_aerobic_limit_bpm": registry.zone2Max,
                "z4_threshold_limit_bpm": registry.zone4Max,
                "ftp_watts": registry.functionalThresholdPower,
                "target_tdee_kcal": registry.effectiveTDEE,
                "protein_floor_g": 215 // ✨ INJECTED: Mandatory macro floor
            ],
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
                "status": yesterdayNet < -500 ? "Critical Deficit" : (yesterdayNet < -50 ? "Optimal Cut" : "Maintenance")
            ],
            "biomechanics_last_session": [
                "avg_gct_ms": sessions.first?.groundContactTime ?? 0,
                "avg_osc_cm": sessions.first?.verticalOscillation ?? 0
            ],
            "kinetic_output_last_session": [
                "avg_hr_bpm": sessions.first?.averageHR ?? 0,
                "intensity_vs_z2": (sessions.first?.averageHR ?? 0) / Double(registry.zone2Max > 0 ? registry.zone2Max : 1),
                "avg_power_w": sessions.first?.avgPower ?? 0
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: sensorData, options: .prettyPrinted),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "{ \"error\": \"Data compression fault\" }"
    }
    
    private var compiledPayload: String {
        let registry = registries.first ?? UserRegistry()
        
        // 🎯 Find active target
        let activeObjective = fetchedObjectives.first(where: { !$0.isCompleted })
        let objectiveString = activeObjective != nil ? "\(activeObjective!.eventName) in \(activeObjective!.location) on \(activeObjective!.targetDate.formatted(date: .abbreviated, time: .omitted)) (Target Pace: \(activeObjective!.targetPace), Target Power: \(activeObjective!.targetPower)W)" : "Maintain Base Fitness"
        
        let missionContext = todayMission != nil ? "Activity: \(todayMission!.missionTitle)\nTarget TSS: \(Int(todayMission!.targetLoad))\nFuel Tier: \(todayMission!.fuelTier)\nCoach Notes: \(todayMission!.coachNotes)" : "No directive scheduled for today. Focus on dopamine-safe, active recovery."
        
        // ✨ INJECTED: Updated Header and Request for HYBRID EVOLUTION v3
        let header = "[System: Dragster OS - Telemetry Feed]\nStrategic Objective: \(objectiveString)\nCommand System Assessment: \(dynamicCommandStatus)\n\n"
        
        let request = "Request: You are THE HYBRID EVOLUTION v3 — an elite, fiercely supportive, and neurodivergent-optimized performance coach. Your athlete is Jamie. Execute the MANDATORY 08:00 BRIEF based on the Dragster OS telemetry below. Structure your response exactly into: 1. DAILY DRAGSTER OS TELEMETRY, 2. MACRO BLUEPRINT (enforcing the 215g protein floor against the Target TDEE), and 3. TRAINING ALIGNMENT. Frame any required rest as 'charging the battery' or 'mindful reloading' to soothe ADHD impatience. Tone: Warm, elegant, fiercely supportive, and deeply structured.\n\n"
        
        let directiveData = "// Today's Directive //\n\(missionContext)\n\n"
        let jsonData = "// Clinical Telemetry JSON //\n\(compiledJSONPayload)"
        
        return header + request + directiveData + jsonData
    }
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // 1. SYSTEM STATUS HEADER
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Intelligence Payload")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.prime)
                            Text(isCompiling ? "Gathering Telemetry..." : "Payload Secured")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(isCompiling ? .orange : .green)
                        }
                        Spacer()
                        
                        Button(action: { showingRegistry = true }) {
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(ColorTheme.prime)
                                .padding(8)
                                .background(ColorTheme.surface)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    
                    if let reg = registries.first {
                        HStack(spacing: 12) {
                            ZoneIndicator(label: "Z2", value: "\(reg.zone2Max)", color: ColorTheme.prime)
                            ZoneIndicator(label: "Z4", value: "\(reg.zone4Max)", color: .orange)
                            ZoneIndicator(label: "VO2", value: String(format: "%.1f", reg.vo2Max), color: .purple)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                
                if isCompiling {
                    ProgressView().tint(ColorTheme.prime).frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    
                    // 2. HUMAN-READABLE DOSSIER
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Dossier Summary")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            DossierRow(label: "System Flags", value: dynamicCommandStatus, color: dynamicCommandStatus.contains("Red") || dynamicCommandStatus.contains("Warning") ? ColorTheme.critical : .green)
                            
                            Divider().background(ColorTheme.surfaceBorder)
                            
                            DossierRow(label: "Today's Mission", value: todayMission?.missionTitle ?? "Rest Day", color: ColorTheme.prime)
                            
                            if let mission = todayMission {
                                HStack(spacing: 16) {
                                    DossierSubStat(label: "Load", value: "\(Int(mission.targetLoad)) TSS")
                                    DossierSubStat(label: "Fuel", value: mission.fuelTier)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3. RAW EXPORT
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Raw Export String")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        TextEditor(text: .constant(compiledPayload))
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(ColorTheme.textPrimary)
                            .frame(height: 150)
                            .padding(8)
                            .background(ColorTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ColorTheme.surfaceBorder, lineWidth: 1))
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 4. TRANSMIT BUTTON
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
                            Text(isCopied ? "Payload Copied" : "Copy to Clipboard")
                        }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
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
        .applyTacticalOS(title: "AI Briefing", showBack: false)
        .sheet(isPresented: $showingRegistry) {
            RegistrySettingsView()
        }
        .task {
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
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
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
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ColorTheme.surfaceBorder.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct ZoneIndicator: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ColorTheme.surfaceBorder.opacity(0.3))
        .clipShape(Capsule())
    }
}
