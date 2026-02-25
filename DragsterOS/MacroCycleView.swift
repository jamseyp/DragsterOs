import SwiftUI

// 🎨 ARCHITECTURE: A fluid, scrollable timeline of the entire training block.
// Uses LazyVStack to ensure memory stays perfectly flat even if the CSV contains 100+ rows.

struct MacroCycleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var schedule: [TacticalMission] = []
    
    // Calculate today's date string to dynamically highlight the current row
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
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
                            .foregroundStyle(.gray)
                        
                        Text("MACRO-CYCLE")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // THE TIMELINE
                    LazyVStack(spacing: 16) {
                                            ForEach(schedule) { mission in
                                                // ✨ THE POLISH: We wrap the row in a routing link
                                                NavigationLink(destination: MissionDetailView(mission: mission)) {
                                                    MacroCycleRow(mission: mission, isToday: mission.dateString == todayString)
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
        .onAppear {
            // Load the array instantly from memory
            schedule = CSVParserEngine.fetchFullMacroCycle()
        }
    }
}

// ✨ THE POLISH: A hyper-compact row designed for maximum data density
struct MacroCycleRow: View {
    let mission: TacticalMission
    let isToday: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            
            // 1. The Date Block
            VStack {
                Text(mission.dateString.prefix(3).uppercased()) // "MAR"
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(isToday ? ColorTheme.background : .gray)
                
                Text(mission.dateString.suffix(2)) // "09"
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(isToday ? ColorTheme.background : .white)
            }
            .frame(width: 50, height: 50)
            .background(isToday ? ColorTheme.prime : ColorTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 2. The Objective Data
            VStack(alignment: .leading, spacing: 4) {
                Text(mission.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isToday ? ColorTheme.prime : .white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text(mission.powerTarget)
                    }
                    .foregroundStyle(.yellow)
                    
                    Text("•")
                        .foregroundStyle(.gray)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text(mission.fuel.rawValue.components(separatedBy: " ").first ?? "")
                    }
                    .foregroundStyle(mission.fuel.color)
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
