import SwiftUI
import SwiftData

struct MacroCycleView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 🗄️ PERSISTENCE
    @Query(sort: \OperationalDirective.date, order: .forward) private var macroCycle: [OperationalDirective]
    
    @State private var showingAddMission = false
    
    // Grid settings for the 4-week overview
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    // Calculate today's date string
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                
                // ✨ 1. THE STRATEGIC TIMELINE GRID (The New Component)
                VStack(alignment: .leading, spacing: 12) {
                    Text("4-WEEK DEPLOYMENT WINDOW")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        // Display the next 28 days for tactical planning
                        ForEach(macroCycle.prefix(28)) { directive in
                            VStack(spacing: 4) {
                                Text(directive.dateString.suffix(2))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(directive.dateString == todayString ? ColorTheme.background : ColorTheme.textPrimary)
                                
                                Circle()
                                    .fill(gridFuelColor(for: directive.fuelTier))
                                    .frame(width: 6, height: 6)
                            }
                            .frame(height: 45)
                            .frame(maxWidth: .infinity)
                            .background(directive.dateString == todayString ? ColorTheme.prime : ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(directive.isAlteredBySystem ? ColorTheme.critical : Color.clear, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // ✨ 2. THE DETAILED DIRECTIVE LIST (Your Existing Logic)
                VStack(alignment: .leading, spacing: 16) {
                    Text("IMMEDIATE DIRECTIVES")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(macroCycle) { plannedMission in
                            let tactical = mapToTactical(plannedMission)
                            
                            NavigationLink(destination: MissionDetailView(mission: tactical)) {
                                MacroCycleRow(mission: plannedMission, isToday: plannedMission.dateString == todayString)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
        // ✨ THE OS WRAPPER (Handles navigation and global state)
        .applyTacticalOS(title: "MACRO-CYCLE STRATEGY")
        
        // ✨ FLOATING TACTICAL OVERLAY
        .overlay(alignment: .bottomTrailing) {
            TacticalActionButton(icon: "plus", color: ColorTheme.prime) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingAddMission = true
            }
            .padding(24)
        }
        .sheet(isPresented: $showingAddMission) {
            AddPlannedActivitySheet()
        }
    }
    
    // MARK: - 🧠 HELPERS
    
    private func gridFuelColor(for tier: String) -> Color {
        if tier.contains("LOW") { return .green }
        if tier.contains("MED") { return .yellow }
        if tier.contains("HIGH") { return ColorTheme.critical }
        if tier.contains("RACE") { return .purple }
        return ColorTheme.textMuted
    }
    
    private func mapToTactical(_ planned: OperationalDirective) -> TacticalMission {
        let mappedFuel: FuelTier
        if planned.fuelTier.contains("LOW") { mappedFuel = .low }
        else if planned.fuelTier.contains("MED") { mappedFuel = .medium }
        else if planned.fuelTier.contains("HIGH") { mappedFuel = .high }
        else if planned.fuelTier.contains("RACE") { mappedFuel = .race }
        else { mappedFuel = .medium }
        
        return TacticalMission(
            dateString: planned.dateString,
            title: planned.activity.uppercased(),
            powerTarget: planned.powerTarget.uppercased(),
            fuel: mappedFuel,
            coachNotes: planned.coachNotes,
            isAltered: planned.isAlteredBySystem
        )
    }
}

// MARK: - ✨ THE POLISH: ROW COMPONENT
struct MacroCycleRow: View {
    let mission: OperationalDirective
    let isToday: Bool
    
    private var fuelColor: Color {
        if mission.fuelTier.contains("LOW") { return .green }
        if mission.fuelTier.contains("MED") { return .yellow }
        if mission.fuelTier.contains("HIGH") { return ColorTheme.critical }
        if mission.fuelTier.contains("RACE") { return .purple }
        return ColorTheme.textMuted
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Text(mission.dateString.prefix(3).uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(isToday ? ColorTheme.background : ColorTheme.textMuted)
                
                Text(mission.dateString.suffix(2))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(isToday ? ColorTheme.background : ColorTheme.textPrimary)
            }
            .frame(width: 50, height: 50)
            .background(isToday ? ColorTheme.prime : ColorTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mission.activity.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isToday ? ColorTheme.prime : ColorTheme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text(mission.powerTarget)
                    }
                    .foregroundStyle(.orange)
                    
                    Text("•")
                        .foregroundStyle(ColorTheme.textMuted)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text(mission.fuelTier.components(separatedBy: " ").first ?? "")
                    }
                    .foregroundStyle(fuelColor)
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            Spacer()
        }
        .padding(12)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isToday ? ColorTheme.prime.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
