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
    
    @State private var rmssd: Double = 0
    @State private var eliteScore: Int = 0
    @State private var hf: Double = 0
    @State private var lf: Double = 0
    
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
                        // ... inside the Form ...
                        Section(header: Text("ELITE HRV PROTOCOL").font(.caption.monospaced())) {
                            HStack {
                                Text("RMSSD (ms)").foregroundStyle(ColorTheme.prime)
                                Spacer()
                                TextField("0", value: $rmssd, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("Readiness (1-10)").foregroundStyle(ColorTheme.prime)
                                Spacer()
                                TextField("0", value: $eliteScore, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("HF (High Freq)")
                                Spacer()
                                TextField("0", value: $hf, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            }
                            HStack {
                                Text("LF (Low Freq)")
                                Spacer()
                                TextField("0", value: $lf, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            }
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
