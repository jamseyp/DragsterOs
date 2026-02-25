import SwiftUI
import SwiftData
import Charts

// 🎨 ARCHITECTURE: The Mass & Efficiency dashboard.
// Utilizes Apple's native Swift Charts for high-performance, interactive data visualization.

struct ChassisView: View {
    @Environment(\.modelContext) private var context
    
    // Fetch snapshots chronologically for the chart
    @Query(sort: \ChassisSnapshot.date, order: .forward)
    private var snapshots: [ChassisSnapshot]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // 1️⃣ HEADER & PRIME METRIC
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STRUCTURAL EFFICIENCY")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.gray)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.2f", snapshots.last?.powerToWeightRatio ?? 0.0))
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                            
                            Text("W/kg")
                                .font(.headline.bold())
                                .foregroundStyle(.cyan)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    if snapshots.isEmpty {
                        ContentUnavailableView(
                            "NO DATA SAMPLES",
                            systemImage: "chart.xyaxis.line",
                            description: Text("Log your monthly structural snapshots to map your W/kg evolution.")
                        )
                        .foregroundStyle(.cyan)
                    } else {
                        // 2️⃣ THE FLUID SWIFT CHART
                        VStack(alignment: .leading, spacing: 16) {
                            Text("EVOLUTION TRAJECTORY")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(.gray)
                            
                            Chart {
                                ForEach(snapshots) { snapshot in
                                    // The Area fill underneath the line
                                    AreaMark(
                                        x: .value("Date", snapshot.date, unit: .month),
                                        y: .value("W/kg", snapshot.powerToWeightRatio)
                                    )
                                    // Creates a beautiful fade effect to pure black
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.cyan.opacity(0.5), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    // Smooths the harsh data points into an elegant curve
                                    .interpolationMethod(.catmullRom)
                                    
                                    // The crisp defining line on top
                                    LineMark(
                                        x: .value("Date", snapshot.date, unit: .month),
                                        y: .value("W/kg", snapshot.powerToWeightRatio)
                                    )
                                    .foregroundStyle(.cyan)
                                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .interpolationMethod(.catmullRom)
                                    
                                    // Data Point Nodes
                                    PointMark(
                                        x: .value("Date", snapshot.date, unit: .month),
                                        y: .value("W/kg", snapshot.powerToWeightRatio)
                                    )
                                    .foregroundStyle(.white)
                                    .symbolSize(50)
                                }
                            }
                            // Restrict the Y-Axis to make the chart visually dynamic
                            .chartYScale(domain: .automatic(includesZero: false))
                            .frame(height: 240)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .month)) { _ in
                                    AxisGridLine().foregroundStyle(.white.opacity(0.1))
                                    AxisTick().foregroundStyle(.clear)
                                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                                        .foregroundStyle(.gray)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { _ in
                                    AxisGridLine().foregroundStyle(.white.opacity(0.1))
                                    AxisValueLabel()
                                        .foregroundStyle(.gray)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        // 3️⃣ BIOMECHANICAL SYMMETRY GAUGE
                        if let current = snapshots.last {
                            SymmetryCard(snapshot: current)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle("MASS & EFFICIENCY")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: seedDatabase) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.cyan)
                }
            }
        }
    }
    
    // MARK: - Testing Data Injection
    private func seedDatabase() {
        // Based on your CSV data:
        let jan = ChassisSnapshot(
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!,
            weightKG: 99.3, peakPowerWatts: 557.0, leftLegCM: 55.0, rightLegCM: 55.0
        )
        let feb = ChassisSnapshot(
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!,
            weightKG: 96.7, peakPowerWatts: 771.0, leftLegCM: 54.0, rightLegCM: 56.0
        )
        
        context.insert(jan)
        context.insert(feb)
        
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}

// ✨ THE POLISH: A highly specialized view for visualizing leg circumference parity.
struct SymmetryCard: View {
    let snapshot: ChassisSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("LOWER BODY SYMMETRY")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(.gray)
                Spacer()
                if snapshot.isSymmetrical {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                }
            }
            
            HStack(spacing: 0) {
                // Left Leg Block
                VStack(spacing: 8) {
                    Text("LEFT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.gray)
                    Text("\(snapshot.leftLegCM, specifier: "%.1f")")
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("cm")
                        .font(.caption2.bold())
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                
                Divider().background(Color.white.opacity(0.2))
                
                // Right Leg Block
                VStack(spacing: 8) {
                    Text("RIGHT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.gray)
                    Text("\(snapshot.rightLegCM, specifier: "%.1f")")
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("cm")
                        .font(.caption2.bold())
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Tactical Warning Note
            if !snapshot.isSymmetrical {
                Text("⚠️ STRUCTURAL IMBALANCE DETECTED. Focus on unilateral lifting protocols (Bulgarian Split Squats) to correct the \(String(format: "%.1f", abs(snapshot.leftLegCM - snapshot.rightLegCM)))cm deficit.")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.yellow)
                    .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(snapshot.isSymmetrical ? Color.green.opacity(0.3) : Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}
