import SwiftUI
import SwiftData

// MARK: - 📝 SHEET: MANUAL TELEMETRY OVERRIDE
struct ManualTelemetrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    // We pass these in from the parent view
    var log: TelemetryLog?
    var history: [TelemetryLog]
    
    // Local state for editing to prevent binding issues with Optionals
    @State private var manualHRV: Double = 0
    @State private var manualRHR: Double = 0
    @State private var manualSleep: Double = 0
    @State private var manualWeight: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("MANUAL OVERRIDE").font(.caption.monospaced())) {
                        HStack {
                            Text("HRV (ms)")
                            Spacer()
                            TextField("0", value: $manualHRV, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(ColorTheme.prime)
                        }
                        
                        HStack {
                            Text("RHR (bpm)")
                            Spacer()
                            TextField("0", value: $manualRHR, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(ColorTheme.prime)
                        }
                        
                        HStack {
                            Text("Sleep (hrs)")
                            Spacer()
                            TextField("0", value: $manualSleep, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(ColorTheme.prime)
                        }
                        
                        HStack {
                            Text("Weight (kg)")
                            Spacer()
                            TextField("0", value: $manualWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(ColorTheme.prime)
                        }
                    }
                    .listRowBackground(ColorTheme.panel)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("EDIT VITALS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("CANCEL") { dismiss() }.foregroundStyle(ColorTheme.textMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("SAVE") { saveManualData() }
                        .font(.caption.bold().monospaced())
                        .foregroundStyle(ColorTheme.prime)
                }
            }
            .onAppear {
                if let current = log {
                    manualHRV = current.hrv
                    manualRHR = current.restingHR
                    manualSleep = current.sleepDuration
                    manualWeight = current.weightKG
                }
            }
        }
    }
    
    private func saveManualData() {
        if let current = log {
            current.hrv = manualHRV
            current.restingHR = manualRHR
            current.sleepDuration = manualSleep
            current.weightKG = manualWeight
            
            current.readinessScore = ReadinessEngine.computeReadiness(
                todayHRV: manualHRV,
                todaySleep: manualSleep,
                history: history
            )
        } else {
            let newLog = TelemetryLog(
                date: Calendar.current.startOfDay(for: .now),
                hrv: manualHRV,
                restingHR: manualRHR,
                sleepDuration: manualSleep,
                weightKG: manualWeight,
                readinessScore: ReadinessEngine.computeReadiness(todayHRV: manualHRV, todaySleep: manualSleep, history: history)
            )
            context.insert(newLog)
        }
        
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
