import SwiftUI

// 🎨 ARCHITECTURE: The Drill-Down Canvas.
// This view is completely stateless; it purely renders the TacticalMission passed to it.

struct MissionDetailView: View {
    let mission: TacticalMission
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            ColorTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // 1️⃣ THE OBJECTIVE
                    DetailMissionCard(
                        title: "PRIMARY OBJECTIVE",
                        icon: "target",
                        color: ColorTheme.prime
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
                            .foregroundStyle(.yellow)
                        }
                    }
                    
                    // 2️⃣ THE FUEL MAP
                    DetailMissionCard(
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
                    DetailMissionCard(
                        title: "COACH NOTES",
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
                .padding()
            }
        }
        .navigationTitle(mission.dateString.uppercased())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ✨ THE POLISH: A scoped, reusable card for the detail view
struct DetailMissionCard<Content: View>: View {
    var title: String
    var icon: String
    var color: Color
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 12, weight: .black, design: .monospaced))
            .foregroundStyle(color)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
