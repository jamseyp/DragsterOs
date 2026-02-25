import SwiftUI
import SwiftData

// 🎨 ARCHITECTURE: A highly stylized, dynamic Whiteboard.
// It queries the live Readiness Score from SwiftData and feeds it into the MissionEngine.

struct MissionView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 1. SWIFTDATA INTEGRATION
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    // 2. STATE
    @State private var todaysMission: TacticalMission?
    @State private var hasAnimated: Bool = false
    
    // Calculate current readiness from the database
    private var currentReadiness: Double {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let todayLog = logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) })
        return todayLog?.readinessScore ?? 100.0 // Default to 100 if no data yet
    }
    
    var body: some View {
        ZStack {
            // Pure Black Canvas
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                // HEADER
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TACTICAL BRIEFING")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.gray)
                        
                        Text(Date().formatted(.dateTime.month().day().weekday(.wide)).uppercased())
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    
                    // The Readiness Badge
                    VStack(alignment: .trailing) {
                        Text("READINESS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.gray)
                        Text("\(Int(currentReadiness))")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundStyle(currentReadiness < 40 ? .red : .cyan)
                            .contentTransition(.numericText())
                    }
                }
                .padding(.top, 20)
                
                Divider().background(Color.white.opacity(0.2))
                
                if let mission = todaysMission {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            
                            // 🚨 OVERRIDE WARNING
                            if mission.isAltered {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("SYSTEM OVERRIDE ENGAGED")
                                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                }
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                // Fluid pulse animation for the warning
                                .opacity(hasAnimated ? 1.0 : 0.6)
                                .animation(.easeInOut(duration: 1.0).repeatForever(), value: hasAnimated)
                            }
                            
                            // 1️⃣ THE OBJECTIVE
                            MissionCard(
                                title: "PRIMARY OBJECTIVE",
                                icon: "target",
                                color: mission.isAltered ? .red : .cyan
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(mission.title)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    
                                    HStack {
                                        Image(systemName: "bolt.fill")
                                        Text("TARGET: \(mission.powerTarget)")
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundStyle(mission.isAltered ? .red : .yellow)
                                }
                            }
                            
                            // 2️⃣ THE FUEL MAP
                            MissionCard(
                                title: "FUEL INJECTION",
                                icon: "flame.fill",
                                color: mission.fuel.color
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(mission.fuel.rawValue)
                                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                                        .foregroundStyle(mission.fuel.color)
                                    
                                    Text(mission.fuel.macros)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            
                            // 3️⃣ PIT WALL NOTES
                            MissionCard(
                                title: "PIT WALL TRANSMISSION",
                                icon: "waveform",
                                color: .purple
                            ) {
                                Text(mission.coachNotes)
                                    .font(.system(size: 16, weight: .medium, design: .default))
                                    .italic()
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } else {
                    Spacer()
                    ProgressView().tint(.cyan)
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateBriefing()
            hasAnimated = true
        }
    }
    
    // MARK: - Mechanical Execution
    
    private func generateBriefing() {
        // 1. Fetch what the spreadsheet *wants* you to do
        let scheduled = MissionEngine.fetchScheduledMission()
        
        // 2. Pass it through the Race Engineer with your live Readiness Score
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            self.todaysMission = MissionEngine.prescribeMission(scheduled: scheduled, readiness: currentReadiness)
        }
        
        // Tactile clunk when the briefing loads
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}


