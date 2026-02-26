import SwiftUI
import SwiftData

struct ObjectiveWidget: View {
    @Query private var objectives: [StrategicObjective]
    @State private var showingSetup = false
    
    // 🧠 Calculate the T-Minus countdown dynamically
    private var daysRemaining: Int {
        guard let target = objectives.first?.targetDate else { return 0 }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let startOfTarget = calendar.startOfDay(for: target)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget)
        return components.day ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let objective = objectives.first {
                // ✨ ACTIVE OBJECTIVE UI
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("STRATEGIC OBJECTIVE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.prime)
                        Spacer()
                        Image(systemName: "crosshair")
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(daysRemaining == 0 ? "EXECUTION DAY" : "T-MINUS \(max(0, daysRemaining)) DAYS")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(daysRemaining <= 7 ? ColorTheme.critical : ColorTheme.textPrimary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        
                        Text("\(objective.eventName) // \(objective.location)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch.fill")
                            Text(objective.targetPace)
                        }
                        .foregroundStyle(.cyan)
                        
                        if objective.targetPower > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                Text("\(objective.targetPower)W")
                            }
                            .foregroundStyle(.orange)
                        }
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .padding(20)
                .background(ColorTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onLongPressGesture {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showingSetup = true
                }
                
            } else {
                // ⚠️ NO OBJECTIVE SET UI
                Button(action: { showingSetup = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "scope")
                            .font(.system(size: 24))
                        Text("SET PRIMARY STRATEGIC OBJECTIVE")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .foregroundStyle(ColorTheme.background)
                    .background(ColorTheme.prime)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .sheet(isPresented: $showingSetup) {
            ObjectiveSetupSheet()
        }
    }
}
