import SwiftUI
import Charts
import SwiftData

// MARK: - 🧬 AXIOM COMPONENT: KINETIC LOAD WIDGET
struct KineticLoadWidget: View {
    // 🗄️ DATA INJECTION
    @Query(sort: \KineticSession.date, order: .forward) private var sessions: [KineticSession]
    
    // 🕹️ STATE & INTERACTION
    @State private var timeHorizon: Int = 42 // Default to a 6-week macrocycle
    @State private var loadTimeSeries: [DailyLoadData] = []
    @State private var currentProfile: KineticLoadEngine.LoadProfile = .init(ctl: 0, atl: 0)
    @State private var isCalculating = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // --- 1. HEADER & HORIZON SELECTOR ---
            HStack {
                Text("KINETIC LOAD PROFILE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                
                Spacer()
                
                Picker("Horizon", selection: $timeHorizon) {
                    Text("4W").tag(28)
                    Text("6W").tag(42)
                    Text("12W").tag(84)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                .onChange(of: timeHorizon) { _ in
                    recalculateTrajectory()
                }
            }
            
            if isCalculating {
                ProgressView()
                    .tint(ColorTheme.prime)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                
                // --- 2. CURRENT METRICS (CTL, ATL, TSB) ---
                HStack(alignment: .top, spacing: 16) {
                    LoadMetricView(
                        title: "BASE FITNESS",
                        value: currentProfile.ctl,
                        color: .blue,
                        subtitle: "CTL"
                    )
                    
                    Divider().background(ColorTheme.surfaceBorder)
                    
                    LoadMetricView(
                        title: "SYSTEMIC FATIGUE",
                        value: currentProfile.atl,
                        color: ColorTheme.critical,
                        subtitle: "ATL"
                    )
                    
                    Divider().background(ColorTheme.surfaceBorder)
                    
                    LoadMetricView(
                        title: "ADAPTATION STATUS",
                        value: currentProfile.tsb,
                        color: currentProfile.tsb >= -15 ? .green : .orange,
                        subtitle: "TSB"
                    )
                }
                .padding(.horizontal, 4)
                
                // --- 3. DUAL-AXIS KINETIC CHART ---
                Chart(loadTimeSeries) { dataPoint in
                    // Base Fitness (CTL)
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Fitness (CTL)", dataPoint.profile.ctl)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Fitness (CTL)", dataPoint.profile.ctl)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Systemic Fatigue (ATL)
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Fatigue (ATL)", dataPoint.profile.atl)
                    )
                    .foregroundStyle(ColorTheme.critical)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                }
                .chartYScale(domain: .automatic(includesZero: true))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: timeHorizon)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                        AxisValueLabel(format: .dateTime.month().day(), centered: false)
                            .foregroundStyle(ColorTheme.textMuted)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                        AxisValueLabel()
                            .foregroundStyle(ColorTheme.textMuted)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                }
                .frame(height: 180)
                
                // --- 4. ✨ NEW: PHYSIOLOGICAL INSIGHT BOX ---
                VStack(alignment: .leading, spacing: 6) {
                    Text("SYSTEM INSIGHT: KINETIC BALANCE")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                    
                    Text("This profile maps your structural readiness for the 4:59 min/km pace. Base Fitness (CTL) is the aerobic foundation you've built. Systemic Fatigue (ATL) reflects your 7-day training strain. Adaptation Status (TSB) is the balance: maintain a slightly negative state during the Build phase, but target a positive TSB to shed fatigue before race day.")
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundStyle(ColorTheme.textMuted)
                        .lineSpacing(2)
                }
                .padding(.leading, 12)
                .padding(.top, 4)
                .overlay(
                    Rectangle()
                        .fill(ColorTheme.prime.opacity(0.5))
                        .frame(width: 2),
                    alignment: .leading
                )
            }
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            recalculateTrajectory()
        }
    }
    
    // MARK: - 🧠 ASYNC MATHEMATICS
    private func recalculateTrajectory() {
        isCalculating = true
        
        Task.detached(priority: .userInitiated) {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            let startDate = calendar.date(byAdding: .day, value: -self.timeHorizon, to: today)!
            
            var series: [DailyLoadData] = []
            
            for dayOffset in 0...self.timeHorizon {
                guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
                let profile = KineticLoadEngine.computeLoad(history: self.sessions, upTo: targetDate)
                series.append(DailyLoadData(date: targetDate, profile: profile))
            }
            
            let todayProfile = KineticLoadEngine.computeLoad(history: self.sessions, upTo: today)
            
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.loadTimeSeries = series
                    self.currentProfile = todayProfile
                    self.isCalculating = false
                }
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        }
    }
}

// MARK: - 🧱 SUB-COMPONENTS
struct LoadMetricView: View {
    let title: String
    let value: Double
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(value))")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DailyLoadData: Identifiable {
    let id = UUID()
    let date: Date
    let profile: KineticLoadEngine.LoadProfile
}
