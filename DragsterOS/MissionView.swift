import SwiftUI
import SwiftData

struct MissionView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Environment(\.modelContext) private var context
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    @State private var todaysMission: TacticalMission?
    @State private var isCalculating = true
    
    // 🧠 Dynamically calculates current readiness to feed the override engine
    private var currentReadiness: Double {
        let today = Calendar.current.startOfDay(for: .now)
        if let log = logs.first(where: { Calendar.current.startOfDay(for: $0.date) == today }) {
            return Double(log.readinessScore)
        }
        return 100.0 // Defaults to fresh if no log exists for today yet
    }
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        ZStack {
            ColorTheme.background.ignoresSafeArea()
            
            if isCalculating {
                // ✨ TACTICAL LOADING STATE
                VStack(spacing: 16) {
                    ProgressView().tint(ColorTheme.prime)
                        .scaleEffect(1.2)
                    Text("DECRYPTING DAILY PROTOCOL...")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                }
            } else if let mission = todaysMission {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // 1. HEADER
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mission.dateString.uppercased())
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            Text("TACTICAL BRIEFING")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(ColorTheme.textPrimary)
                        }
                        .padding(.top, 20)
                        
                        // 2. 🚨 SYSTEM OVERRIDE WARNING
                        if mission.isAltered {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SYSTEM OVERRIDE ACTIVE")
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                    Text("Protocol downgraded due to critical CNS fatigue.")
                                        .font(.system(size: 10, weight: .medium, design: .default))
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorTheme.critical.opacity(0.15))
                            .foregroundStyle(ColorTheme.critical)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.critical, lineWidth: 1))
                        }
                        
                        // 3. CORE OBJECTIVE BLOCK
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PRIMARY DIRECTIVE")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.prime)
                            
                            Text(mission.title)
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundStyle(ColorTheme.textPrimary)
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.orange)
                                Text(mission.powerTarget)
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textPrimary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ColorTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // 4. FUELING PROTOCOL
                        VStack(alignment: .leading, spacing: 16) {
                            Text("NUTRITION PROTOCOL")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(mission.fuel.color)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(mission.fuel.color)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mission.fuel.rawValue)
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundStyle(ColorTheme.textPrimary)
                                    
                                    Text(mission.fuel.macros)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(ColorTheme.textMuted)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ColorTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // 5. COMMANDER'S INTENT (Notes)
                        if !mission.coachNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("COMMANDER'S INTENT")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textMuted)
                                
                                Text(mission.coachNotes)
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .foregroundStyle(ColorTheme.textPrimary)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            // Tactical left-border styling
                            .overlay(
                                Rectangle()
                                    .fill(ColorTheme.surfaceBorder)
                                    .frame(width: 3),
                                alignment: .leading
                            )
                        }
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await generateDailyMission()
        }
    }
    
    // MARK: - 🧠 LOGIC: MISSION GENERATION
    private func generateDailyMission() async {
        // Simulated UI decryption delay (0.6 seconds)
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        // 1. Fetch raw CSV data from SwiftData
        let rawMission = MissionEngine.fetchTodayMission(context: context)
        
        // 2. Algorithm checks for fatigue penalties based on this morning's telemetry
        let finalMission = MissionEngine.prescribeMission(scheduled: rawMission, readiness: currentReadiness)
        
        // 3. Render UI
        await MainActor.run {
            self.todaysMission = finalMission
            self.isCalculating = false
        }
    }
}
