import SwiftUI
import SwiftData

// 🎨 ARCHITECTURE: A fluid, scrollable timeline of the entire training block.
// Uses LazyVStack to ensure memory stays perfectly flat even if the database contains 100+ rows.

struct MacroCycleView: View {
    @Environment(\.dismiss) private var dismiss
    
    // ✨ THE UPGRADE: Pull the schedule directly from the SwiftData cache, sorted by date!
    @Query(sort: \PlannedMission.date, order: .forward) private var macroCycle: [PlannedMission]
    @State private var showingAddMission = false
    
    // Calculate today's date string to dynamically highlight the current row
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ZStack {
            ColorTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // HEADER
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STRATEGIC VISIBILITY")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted) // 🎨 THEME FIX
                        
                        Text("MACRO-CYCLE")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(ColorTheme.textPrimary) // 🎨 THEME FIX
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // THE TIMELINE
                    LazyVStack(spacing: 16) {
                        ForEach(macroCycle) { plannedMission in
                            // Map the SwiftData model back to the UI struct for the Detail View
                            let tactical = mapToTactical(plannedMission)
                            
                            // ✨ THE POLISH: We wrap the row in a routing link
                            NavigationLink(destination: MissionDetailView(mission: tactical)) {
                                MacroCycleRow(mission: plannedMission, isToday: plannedMission.dateString == todayString)
                            }
                            // This button style strips away the default blue iOS highlight,
                            // keeping our custom OLED-black and grey styling perfectly intact.
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // ✨ NEW: The Add Button & Sheet
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingAddMission = true
                }) {
                    Image(systemName: "plus.app.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ColorTheme.prime)
                }
            }
        }
        .sheet(isPresented: $showingAddMission) {
            AddPlannedActivitySheet()
        }
    }
    
    // MARK: - 🧠 HELPER: DATA MAPPING
    // Maps the database row into the UI struct expected by your MissionDetailView
    private func mapToTactical(_ planned: PlannedMission) -> TacticalMission {
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

// ✨ THE POLISH: A hyper-compact row designed for maximum data density
struct MacroCycleRow: View {
    let mission: PlannedMission // ✨ Now expects the SwiftData model
    let isToday: Bool
    
    // Dynamically calculate the color from the raw string
    private var fuelColor: Color {
        if mission.fuelTier.contains("LOW") { return .green }
        if mission.fuelTier.contains("MED") { return .yellow }
        if mission.fuelTier.contains("HIGH") { return ColorTheme.critical } // 🎨 THEME FIX
        if mission.fuelTier.contains("RACE") { return .purple }
        return ColorTheme.textMuted // 🎨 THEME FIX
    }
    
    var body: some View {
        HStack(spacing: 16) {
            
            // 1. The Date Block
            VStack {
                Text(mission.dateString.prefix(3).uppercased()) // "MAR"
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(isToday ? ColorTheme.background : ColorTheme.textMuted) // 🎨 THEME FIX
                
                Text(mission.dateString.suffix(2)) // "09"
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(isToday ? ColorTheme.background : ColorTheme.textPrimary) // 🎨 THEME FIX
            }
            .frame(width: 50, height: 50)
            .background(isToday ? ColorTheme.prime : ColorTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 2. The Objective Data
            VStack(alignment: .leading, spacing: 4) {
                Text(mission.activity.uppercased())
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isToday ? ColorTheme.prime : ColorTheme.textPrimary) // 🎨 THEME FIX
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text(mission.powerTarget)
                    }
                    .foregroundStyle(.orange) // 🎨 THEME FIX: Matched to Mechanical Power charts
                    
                    Text("•")
                        .foregroundStyle(ColorTheme.textMuted) // 🎨 THEME FIX
                    
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
        // Subtle border to highlight today's specific objective in the list
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isToday ? ColorTheme.prime.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
