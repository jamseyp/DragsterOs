
import SwiftUI
import SwiftData

struct OperationalBriefingView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    @Query(
        filter: #Predicate<OperationalDirective> { $0.isCompleted == false },
        sort: \OperationalDirective.assignedDate,
        order: .forward
    ) private var activeDirectives: [OperationalDirective]
    
    @State private var todaysMission: OperationalDirective?
    @State private var isCalculating = true
    
    // 🧠 Readiness calculation
    private var currentReadiness: Double {
        let today = Calendar.current.startOfDay(for: .now)
        if let log = logs.first(where: { Calendar.current.startOfDay(for: $0.date) == today }) {
            return Double(log.readinessScore)
        }
        return 100.0
    }
    
    private var isOverrideActive: Bool {
        currentReadiness < 40.0 && todaysMission?.discipline.uppercased() != "REST"
    }
    
    var body: some View {
        Group {
            if isCalculating {
                // ⏳ TACTICAL LOADING STATE
                VStack(spacing: 16) {
                    ProgressView().tint(ColorTheme.prime).scaleEffect(1.2)
                    Text("DECRYPTING DAILY PROTOCOL...")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let mission = todaysMission {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // 🚨 SYSTEM OVERRIDE WARNING
                        if isOverrideActive {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SYSTEM OVERRIDE ACTIVE")
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                    Text("Protocol flagged due to critical CNS fatigue. Advise downgrade to REST or ZONE 1.")
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
                        
                        // 🎯 CORE OBJECTIVE BLOCK
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("PRIMARY DIRECTIVE")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundStyle(ColorTheme.prime)
                                Spacer()
                                Text(mission.discipline.uppercased())
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textMuted)
                            }
                            
                            Text(mission.missionTitle)
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundStyle(ColorTheme.textPrimary)
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                            
                            if mission.discipline.uppercased() != "REST" {
                                HStack(spacing: 24) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.fill").foregroundStyle(ColorTheme.prime)
                                        Text("\(mission.intervalSets)x\(mission.workDurationMinutes)m")
                                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                                            .foregroundStyle(ColorTheme.textPrimary)
                                    }
                                    
                                    if mission.discipline.uppercased() != "STRENGTH" {
                                        HStack(spacing: 8) {
                                            Image(systemName: "bolt.fill").foregroundStyle(.orange)
                                            Text("\(mission.workTargetWatts)W")
                                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                                .foregroundStyle(ColorTheme.textPrimary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ColorTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        // ✨ Design Sync: Subtle Wireframe Border
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ColorTheme.prime.opacity(0.2), lineWidth: 1))
                        
                        // 🧬 FUELING PROTOCOL
                        let cleanFuelTier = mission.fuelTier.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        let macroTarget = NutritionEngine.getTarget(for: cleanFuelTier)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("NUTRITION PROTOCOL")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(getFuelColor(for: cleanFuelTier))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(getFuelColor(for: cleanFuelTier))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("TIER: \(cleanFuelTier)")
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundStyle(ColorTheme.textPrimary)
                                    
                                    Text("\(Int(macroTarget.protein))g P  |  \(Int(macroTarget.carbs))g C  |  \(Int(macroTarget.fat))g F")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(ColorTheme.textMuted)
                                }
                                
                                Spacer()
                                
                                Text("\(Int(macroTarget.calories))\nKCAL")
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textMuted)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ColorTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        // ✨ Design Sync: Subtle Wireframe Border
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ColorTheme.prime.opacity(0.2), lineWidth: 1))
                        
                        // 🧠 COMMANDER'S INTENT
                        if !mission.coachNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("COMMANDER'S INTENT")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundStyle(ColorTheme.prime)
                                Text(mission.coachNotes)
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .foregroundStyle(ColorTheme.textMuted)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ColorTheme.prime.opacity(0.2), lineWidth: 1))
                        }
                        
                        // ⌚ ACTION: TRANSMIT TO COMMAND
                        if mission.discipline.uppercased() != "REST" {
                            Button(action: {
                                Task {
                                    try? await DirectiveScheduler.shared.pushMissionToWatch(directive: mission)
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "applewatch.radiowaves.left.and.right")
                                    Text("TRANSMIT TO WATCH")
                                }
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(ColorTheme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(ColorTheme.prime)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            } else {
                // 🛑 NO MISSION FOUND STATE
                VStack(spacing: 16) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(ColorTheme.textMuted)
                    Text("NO ACTIVE DIRECTIVES")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Text("The command center has no orders for today.")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .applyTacticalOS(title: "OPERATIONAL BRIEFING")
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ColorTheme.prime)
                    .padding()
            }
        }
        .task {
            await locateDailyMission()
        }
    }
    
    // MARK: - 🧠 LOGIC: MISSION GENERATION
    private func locateDailyMission() async {
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        let today = Calendar.current.startOfDay(for: Date())
        
        let missionForToday = activeDirectives.first {
            Calendar.current.startOfDay(for: $0.assignedDate) == today
        }
        
        await MainActor.run {
            self.todaysMission = missionForToday
            self.isCalculating = false
        }
    }
    
    private func getFuelColor(for tier: String) -> Color {
        switch tier {
        case "LOW": return .green
        case "MED": return .yellow
        case "HIGH": return .orange
        case "RACE": return ColorTheme.critical
        default: return .gray
        }
    }
}
