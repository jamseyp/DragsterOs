import SwiftUI
import SwiftData
import Charts

// 🎨 ARCHITECTURE: The Mass & Efficiency dashboard.
// Actively ingests HealthKit body mass and calculates tactical W/kg deltas.

struct ChassisView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChassisSnapshot.date, order: .forward) private var snapshots: [ChassisSnapshot]
    
    @State private var showingLogSheet = false
    
    // 🧠 THE DELTA ENGINE
    private var currentSnapshot: ChassisSnapshot? { snapshots.last }
    private var previousSnapshot: ChassisSnapshot? {
        guard snapshots.count >= 2 else { return nil }
        return snapshots[snapshots.count - 2]
    }
    
    var body: some View {
        ZStack {
            ColorTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // 1️⃣ PRIME METRIC: W/KG
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STRUCTURAL EFFICIENCY")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.gray)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.2f", currentSnapshot?.powerToWeightRatio ?? 0.0))
                                .font(.system(size: 48, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                            
                            Text("W/kg")
                                .font(.headline.bold())
                                .foregroundStyle(ColorTheme.prime)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    if snapshots.isEmpty {
                        ContentUnavailableView(
                            "NO BIOMECHANICAL DATA",
                            systemImage: "scalemass",
                            description: Text("Log your peak power to map your efficiency.")
                        )
                        .foregroundStyle(ColorTheme.prime)
                    } else {
                        // 2️⃣ THE DELTA ANALYSIS
                        if let current = currentSnapshot, let previous = previousSnapshot {
                            StructuralDeltaCard(current: current, previous: previous)
                                .padding(.horizontal)
                        }
                        
                        // 3️⃣ THE FLUID SWIFT CHART
                        VStack(alignment: .leading, spacing: 16) {
                            Text("EVOLUTION TRAJECTORY")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(.gray)
                            
                            Chart {
                                ForEach(snapshots) { snapshot in
                                    AreaMark(
                                        x: .value("Date", snapshot.date, unit: .month),
                                        y: .value("W/kg", snapshot.powerToWeightRatio)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [ColorTheme.prime.opacity(0.5), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                    
                                    LineMark(
                                        x: .value("Date", snapshot.date, unit: .month),
                                        y: .value("W/kg", snapshot.powerToWeightRatio)
                                    )
                                    .foregroundStyle(ColorTheme.prime)
                                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                    .interpolationMethod(.catmullRom)
                                    
                                    PointMark(
                                        x: .value("Date", snapshot.date, unit: .month),
                                        y: .value("W/kg", snapshot.powerToWeightRatio)
                                    )
                                    .foregroundStyle(.white)
                                    .symbolSize(50)
                                }
                            }
                            .chartYScale(domain: .automatic(includesZero: false))
                            .frame(height: 200)
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
                        .background(ColorTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        // 4️⃣ SYMMETRY GAUGE
                        if let current = currentSnapshot {
                            SymmetryCard(snapshot: current)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("MASS & EFFICIENCY")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingLogSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(ColorTheme.prime)
                }
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            BiomechanicalEntrySheet()
        }
    }
}

// ✨ THE POLISH: A modular sheet that pulls weight dynamically from Apple Health
struct BiomechanicalEntrySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var healthManager = HealthKitManager.shared
    
    @State private var weightKG: Double = 0.0
    @State private var peakWatts: Double = 500.0
    @State private var leftLeg: Double = 55.0
    @State private var rightLeg: Double = 55.0
    @State private var isSyncingWeight: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("STRUCTURAL MASS (HEALTHKIT)").font(.caption.monospaced())) {
                        if isSyncingWeight {
                            HStack {
                                ProgressView().tint(ColorTheme.prime)
                                Text("Awaiting Sensor Data...").foregroundStyle(.gray)
                            }
                        } else {
                            VStack(alignment: .leading) {
                                Text("\(weightKG, specifier: "%.1f") kg")
                                    .font(.system(.title2, design: .monospaced, weight: .bold))
                                    .foregroundStyle(ColorTheme.prime)
                                
                                Slider(value: $weightKG, in: 60...120, step: 0.1)
                            }
                        }
                    }
                    .listRowBackground(ColorTheme.surface)
                    
                    Section(header: Text("KINETIC OUTPUT").font(.caption.monospaced())) {
                        VStack(alignment: .leading) {
                            Text("Peak Power: \(Int(peakWatts)) W")
                                .font(.system(.body, design: .monospaced, weight: .bold))
                                .foregroundStyle(.yellow)
                            Slider(value: $peakWatts, in: 200...1000, step: 5)
                        }
                    }
                    .listRowBackground(ColorTheme.surface)
                    
                    Section(header: Text("SYMMETRY PARITY").font(.caption.monospaced())) {
                        VStack(alignment: .leading) {
                            Text("Left Thigh: \(leftLeg, specifier: "%.1f") cm").foregroundStyle(.white)
                            Slider(value: $leftLeg, in: 40...80, step: 0.5)
                        }
                        VStack(alignment: .leading) {
                            Text("Right Thigh: \(rightLeg, specifier: "%.1f") cm").foregroundStyle(.white)
                            Slider(value: $rightLeg, in: 40...80, step: 0.5)
                        }
                    }
                    .listRowBackground(ColorTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("LOG SNAPSHOT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("CANCEL") { dismiss() }
                        .foregroundStyle(ColorTheme.textMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ENGAGE") { saveSnapshot() }
                        .foregroundStyle(ColorTheme.prime)
                        .font(.caption.bold().monospaced())
                        .disabled(isSyncingWeight)
                }
            }
            .task {
                await fetchHealthKitWeight()
            }
        }
    }
    
    private func fetchHealthKitWeight() async {
        isSyncingWeight = true
        do {
            let fetchedWeight = try await healthManager.fetchLatestWeight()
            await MainActor.run {
                if fetchedWeight > 0 { self.weightKG = fetchedWeight }
                else { self.weightKG = 95.0 } // Fallback
                self.isSyncingWeight = false
            }
        } catch {
            await MainActor.run {
                self.weightKG = 95.0
                self.isSyncingWeight = false
            }
        }
    }
    
    private func saveSnapshot() {
        let newLog = ChassisSnapshot(weightKG: weightKG, peakPowerWatts: peakWatts, leftLegCM: leftLeg, rightLegCM: rightLeg)
        context.insert(newLog)
        try? context.save()
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        dismiss()
    }
}

// ✨ THE POLISH: Compares your current metrics to your previous month.
struct StructuralDeltaCard: View {
    let current: ChassisSnapshot
    let previous: ChassisSnapshot
    
    private var powerDelta: Double { current.peakPowerWatts - previous.peakPowerWatts }
    private var weightDelta: Double { current.weightKG - previous.weightKG }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("KINETIC DELTA")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.gray)
                HStack(spacing: 4) {
                    Image(systemName: powerDelta >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(abs(Int(powerDelta))) W")
                }
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(powerDelta >= 0 ? .green : .red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider().background(ColorTheme.surfaceBorder)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("MASS DELTA")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.gray)
                HStack(spacing: 4) {
                    Image(systemName: weightDelta <= 0 ? "arrow.down.right" : "arrow.up.right")
                    Text("\(abs(weightDelta), specifier: "%.1f") KG")
                }
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(weightDelta <= 0 ? .cyan : .yellow)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                VStack(spacing: 8) {
                    Text("LEFT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.gray)
                    Text("\(snapshot.leftLegCM, specifier: "%.1f")")
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                
                Divider().background(Color.white.opacity(0.2))
                
                VStack(spacing: 8) {
                    Text("RIGHT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.gray)
                    Text("\(snapshot.rightLegCM, specifier: "%.1f")")
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }
            
            if !snapshot.isSymmetrical {
                Text("⚠️ STRUCTURAL IMBALANCE DETECTED. Focus on unilateral lifting protocols to correct the \(String(format: "%.1f", abs(snapshot.leftLegCM - snapshot.rightLegCM)))cm deficit.")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.yellow)
                    .padding(.top, 8)
            }
        }
        .padding(20)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(snapshot.isSymmetrical ? Color.green.opacity(0.3) : Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}
