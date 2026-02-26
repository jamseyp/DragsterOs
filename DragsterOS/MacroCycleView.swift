import SwiftUI
import SwiftData

struct MacroCycleView: View {
    @Environment(\.dismiss) private var dismiss
    
    // ✨ Using your new tactical nomenclature
    @Query(sort: \OperationalDirective.date, order: .forward) private var macroCycle: [OperationalDirective]
    
    @State private var showingAddMission = false
    
    // Calculate today's date string to dynamically highlight the current row
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // THE TIMELINE
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
            .padding(.top, 20)
            .padding(.bottom, 100) // Space for the floating button
        }
        // ✨ THE OS WRAPPER
        .applyTacticalOS(title: "MACRO-CYCLE STRATEGY")
        
        // ✨ FLOATING TACTICAL OVERLAY (ADD DIRECTIVE)
        .overlay(alignment: .bottomTrailing) {
            TacticalActionButton(icon: "plus", color: ColorTheme.prime) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingAddMission = true
            }
            .padding(24)
        }
        
        // ✨ CUSTOM BACK BUTTON (Since the system nav bar is hidden)
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ColorTheme.prime)
                    .padding()
            }
        }
        .sheet(isPresented: $showingAddMission) {
            AddPlannedActivitySheet()
        }
    }
    
    // MARK: - 🧠 HELPER: DATA MAPPING
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
            
            // 1. The Date Block
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
            
            // 2. The Objective Data
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
