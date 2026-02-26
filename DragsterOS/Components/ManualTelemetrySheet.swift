import SwiftUI
import SwiftData

// MARK: - 📝 SHEET: MANUAL TELEMETRY OVERRIDE
struct ManualTelemetrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    // We pass these in from the parent view
    var log: TelemetryLog?
    var history: [TelemetryLog]
    
    // ✨ Fetch sessions to calculate mechanical load
    @Query(sort: \KineticSession.date, order: .forward) private var sessions: [KineticSession]
    
    @State private var manualHRV: Double = 0
    @State private var manualRHR: Double = 0
    @State private var manualSleep: Double = 0
    @State private var manualWeight: Double = 0
    
    // Elite Protocol State
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
                    }
                    .listRowBackground(ColorTheme.surface)
                    
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
                    }
                    .listRowBackground(ColorTheme.surface)
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
                    
                    // Load existing Elite Data back into the UI
                    rmssd = current.rmssd ?? 0.0
                    eliteScore = current.eliteReadiness ?? 0
                }
            }
        }
    }
    
    private func saveManualData() {
        // ✨ CALCULATE CURRENT LOAD PROFILE FOR THE ENGINE
        let currentLoad = LoadEngine.computeCurrentLoad(history: sessions)
        
        if let current = log {
            // Standard Vitals
            current.hrv = manualHRV
            current.restingHR = manualRHR
            current.sleepDuration = manualSleep
            current.weightKG = manualWeight
            
            // ✨ THE FIX: Inject the Elite HRV Protocol Data
            current.rmssd = rmssd > 0 ? rmssd : nil
            current.eliteReadiness = eliteScore > 0 ? eliteScore : nil
            
            // Re-run the engine using the updated log
            current.readinessScore = ReadinessEngine.computeReadiness(
                todayLog: current,
                history: history,
                loadProfile: currentLoad
            )
            
        } else {
            // Creating a brand new log for today
            let newLog = TelemetryLog(
                date: Calendar.current.startOfDay(for: .now),
                hrv: manualHRV,
                restingHR: manualRHR,
                sleepDuration: manualSleep,
                weightKG: manualWeight, readinessScore: 0
            )
            
            // ✨ THE FIX: Inject Elite Data into new log
            newLog.rmssd = rmssd > 0 ? rmssd : nil
            newLog.eliteReadiness = eliteScore > 0 ? eliteScore : nil
            
            // Run engine
            newLog.readinessScore = ReadinessEngine.computeReadiness(
                todayLog: newLog,
                history: history,
                loadProfile: currentLoad
            )
            
            context.insert(newLog)
        }
        
        do {
            try context.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("CRITICAL FAULT: Failed to save telemetry to SwiftData. \(error)")
        }
    }
}
