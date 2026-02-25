import SwiftUI
import SwiftData

// MARK: - 🗺️ MISSION ENGINE ROOT
/// The strategic "Pit Wall" of the app. Analyzes readiness and outputs the daily physical protocol.
struct MissionView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    @Query(sort: \KineticSession.date, order: .reverse) private var sessions: [KineticSession]
    
    // MARK: - 🕹️ STATE
    @State private var todaysMission: TacticalMission?
    
    // MARK: - 🧠 CALCULATED BIOMETRICS
    private var currentReadiness: Double {
        logs.first?.readinessScore ?? 100.0
    }
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        ZStack {
            // Theme-aware background
            ColorTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // --- MARK: 📋 HEADER ---
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DAILY PROTOCOL")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            
                            Text("TACTICAL BRIEFING")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(ColorTheme.textPrimary)
                        }
                        
                        Spacer()
                        
                        // Readiness Context Indicator
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("READINESS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            
                            Text("\(Int(currentReadiness))")
                                .font(.system(size: 24, weight: .black, design: .monospaced))
                                .foregroundStyle(currentReadiness < 40 ? ColorTheme.critical : ColorTheme.prime)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // --- MARK: 🚀 MISSION DIRECTIVE ---
                    if let mission = todaysMission {
                        VStack(spacing: 16) {
                            
                            // ⚠️ SYSTEM OVERRIDE BANNER
                            // Appears automatically if readiness dictates a downgrade
                            if mission.isAltered {
                                SystemOverrideBanner()
                            }
                            
                            // 🎯 PRIMARY OBJECTIVE
                            MissionCard(
                                title: "PRIMARY OBJECTIVE",
                                icon: "target",
                                color: mission.isAltered ? ColorTheme.critical : ColorTheme.prime
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(mission.title)
                                        .font(.system(size: 20, weight: .black, design: .rounded))
                                        .foregroundStyle(ColorTheme.textPrimary)
                                    
                                    HStack {
                                        Image(systemName: "bolt.fill")
                                        Text("TARGET: \(mission.powerTarget)")
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundStyle(mission.isAltered ? ColorTheme.critical : ColorTheme.warning)
                                }
                            }
                            
                            // ⛽ FUEL INJECTION
                            MissionCard(
                                title: "FUEL INJECTION",
                                icon: "flame.fill",
                                color: mission.fuel.color
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(mission.fuel.rawValue.uppercased())
                                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                                        .foregroundStyle(mission.fuel.color)
                                    
                                    Text(mission.fuel.macros)
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundStyle(ColorTheme.textPrimary.opacity(0.8))
                                }
                            }
                            
                            // 🎧 PIT WALL TRANSMISSION
                            MissionCard(
                                title: "PIT WALL TRANSMISSION",
                                icon: "waveform",
                                color: ColorTheme.strategy
                            ) {
                                Text(mission.coachNotes)
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .italic()
                                    .foregroundStyle(ColorTheme.textPrimary)
                                    // ✨ UI POLISH: A vertical leading line to simulate a comms transmission
                                    .padding(.leading, 12)
                                    .overlay(
                                        Rectangle()
                                            .fill(ColorTheme.strategy)
                                            .frame(width: 3),
                                        alignment: .leading
                                    )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                        
                    } else {
                        // ⏳ LOADING STATE
                        VStack(spacing: 16) {
                            Spacer().frame(height: 60)
                            ProgressView()
                                .tint(ColorTheme.prime)
                                .scaleEffect(1.5)
                            Text("CALCULATING OPTIMAL PATH...")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateDailyMission()
        }
    }
    
    // MARK: - 🧠 LOGIC: MISSION GENERATION
        private func generateDailyMission() {
            // Modern Swift Concurrency: Replaces DispatchQueue
            Task {
                // Simulated AI/Engine delay (500 million nanoseconds = 0.5 seconds)
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                // Push the UI update back to the Main Thread safely
                await MainActor.run {
                    // Initialize using the exact order of the TacticalMission struct
                    self.todaysMission = TacticalMission(
                        dateString: Date().formatted(date: .abbreviated, time: .omitted), // ✨ Added the missing dateString
                        title: "ZONE 2 AEROBIC BASE",
                        powerTarget: "185W - 210W",
                        fuel: .low,
                        coachNotes: "Keep the cadence high (175+ SPM) and the heart rate strictly below 145 BPM. Let the structural system recover while we build capillary density.",
                        isAltered: currentReadiness < 40 // Moved to the end to match your struct order
                    )
                }
            }
        }
}

// MARK: - 🖼️ COMPONENT: SYSTEM OVERRIDE BANNER
struct SystemOverrideBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("SYSTEM OVERRIDE: LOW READINESS")
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
        }
        // Contrast flip: Black text on Light Mode, White text on Dark Mode against the Red background
        .foregroundStyle(ColorTheme.background)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ColorTheme.critical)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
