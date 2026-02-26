import SwiftUI
import SwiftData
import Charts

struct ChassisCommandView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChassisLog.date, order: .reverse) private var chassisHistory: [ChassisLog]
    
    @State private var showingEntrySheet = false
    
    // 🧠 Computed chronological history for the Charts (they require forward sorting)
    private var chronologicalHistory: [ChassisLog] {
        chassisHistory.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // 1. PRIMARY METRIC GRID
                if let latest = chassisHistory.first {
                    HStack(spacing: 16) {
                        MetricBlock(label: "PARITY INDEX", value: String(format: "%.1f%%", latest.parityIndex), color: latest.parityIndex > 95 ? .green : .orange)
                        MetricBlock(label: "PWR:MASS", value: String(format: "%.2f", latest.powerToWeight), color: ColorTheme.prime)
                    }
                    .padding(.horizontal)
                }
                
                // 2. INITIATE SCAN TRIGGER
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showingEntrySheet = true
                }) {
                    HStack {
                        Image(systemName: "gauge.with.needle.fill")
                        Text("INITIATE HARDWARE SCAN")
                    }
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.prime)
                    .foregroundStyle(ColorTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                if chassisHistory.isEmpty {
                    ContentUnavailableView("NO DATA DETECTED", systemImage: "chart.xyaxis.line", description: Text("Perform a scan to generate structural vectors."))
                        .foregroundStyle(ColorTheme.textMuted)
                } else {
                    
                    // 3. PERFORMANCE VECTORS (Charts)
                    VStack(alignment: .leading, spacing: 20) {
                        Text("STRUCTURAL TRENDS")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        // Chart: Power to Weight
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PWR:MASS (W/kg)").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.orange)
                            Chart(chronologicalHistory) { log in
                                LineMark(x: .value("Date", log.date), y: .value("W/kg", log.powerToWeight))
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(.orange)
                                AreaMark(x: .value("Date", log.date), y: .value("W/kg", log.powerToWeight))
                                    .foregroundStyle(.orange.opacity(0.1))
                            }
                            .frame(height: 120)
                        }
                        
                        // Chart: Parity
                        VStack(alignment: .leading, spacing: 8) {
                            Text("L/R PARITY (%)").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.cyan)
                            Chart(chronologicalHistory) { log in
                                BarMark(x: .value("Date", log.date), y: .value("Parity", log.parityIndex))
                                    .foregroundStyle(log.parityIndex > 95 ? Color.green.gradient : ColorTheme.critical.gradient)
                            }
                            .frame(height: 100)
                            .chartYScale(domain: 80...100)
                        }
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 4. DIAGNOSTIC LOG (History)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DIAGNOSTIC HISTORY")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(chassisHistory, id: \.self) { log in
                                ChassisHistoryRow(log: log)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) { deleteLog(log) } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .applyTacticalOS(title: "CHASSIS & EFFICIENCY", showBack: true)
        .sheet(isPresented: $showingEntrySheet) {
            HardwareScanSheet()
        }
    }
    
    private func deleteLog(_ log: ChassisLog) {
        context.delete(log)
        try? context.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
