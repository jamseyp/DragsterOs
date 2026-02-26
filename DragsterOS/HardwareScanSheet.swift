import SwiftUI
import SwiftData

struct HardwareScanSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // ✨ NEW: Date selection for backfilling historical data
    @State private var scanDate = Date()
    
    // Diagnostic baselines
    @State private var bodyMass: Double = 75.0
    @State private var leftThigh: Double = 55.0
    @State private var rightThigh: Double = 55.0
    @State private var maxWattage: Double = 800.0

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                Form {
                    // ✨ DATE SELECTION SECTION
                    Section(header: Text("TEMPORAL MARKER").font(.caption.monospaced())) {
                        DatePicker("Scan Date", selection: $scanDate, displayedComponents: .date)
                            .tint(ColorTheme.prime)
                            .foregroundStyle(ColorTheme.textPrimary)
                    }
                    .listRowBackground(ColorTheme.surface)
                    
                    Section(header: Text("STRUCTURAL MASS").font(.caption.monospaced())) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Body Mass")
                                Spacer()
                                Text("\(bodyMass, specifier: "%.1f") kg")
                                    .foregroundStyle(ColorTheme.prime)
                                    .font(.system(.body, design: .monospaced).bold())
                            }
                            Slider(value: $bodyMass, in: 50...120, step: 0.1)
                                .tint(ColorTheme.prime)
                        }
                    }
                    .listRowBackground(ColorTheme.surface)
                    
                    Section(header: Text("LEG PARITY (CIRCUMFERENCE)").font(.caption.monospaced())) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Left Thigh")
                                Spacer()
                                Text("\(leftThigh, specifier: "%.1f") cm")
                                    .foregroundStyle(.cyan)
                                    .font(.system(.body, design: .monospaced).bold())
                            }
                            Slider(value: $leftThigh, in: 40...80, step: 0.1)
                                .tint(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Right Thigh")
                                Spacer()
                                Text("\(rightThigh, specifier: "%.1f") cm")
                                    .foregroundStyle(.cyan)
                                    .font(.system(.body, design: .monospaced).bold())
                            }
                            Slider(value: $rightThigh, in: 40...80, step: 0.1)
                                .tint(.cyan)
                        }
                    }
                    .listRowBackground(ColorTheme.surface)
                    
                    Section(header: Text("MAXIMAL KINETIC OUTPUT").font(.caption.monospaced())) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Peak Power")
                                Spacer()
                                Text("\(Int(maxWattage)) W")
                                    .foregroundStyle(.orange)
                                    .font(.system(.body, design: .monospaced).bold())
                            }
                            Slider(value: $maxWattage, in: 200...2000, step: 1)
                                .tint(.orange)
                        }
                    }
                    .listRowBackground(ColorTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("HARDWARE SCAN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ABORT") { dismiss() }
                        .foregroundStyle(ColorTheme.textMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("LOG SCAN") { saveScan() }
                        .font(.caption.monospaced().bold())
                        .foregroundStyle(ColorTheme.prime)
                }
            }
        }
    }
    
    private func saveScan() {
        // ✨ UPDATED: Passing the custom scanDate to the model
        let scan = ChassisLog(
            date: scanDate,
            bodyMass: bodyMass,
            leftThigh: leftThigh,
            rightThigh: rightThigh,
            maxWatts: Int(maxWattage)
        )
        
        context.insert(scan)
        
        do {
            try context.save()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            dismiss()
        } catch {
            print("❌ Hardware Log Fault: \(error.localizedDescription)")
        }
    }
}
