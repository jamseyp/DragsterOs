import SwiftUI
import SwiftData

// MARK: - 📝 SHEET: HYBRID INPUT
struct AddSessionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // ✨ THE PLAN LINK QUERY (This was missing from scope!)
    @Query private var allDirectives: [OperationalDirective]
    
    // ✨ FIXED MANAGER (No @State)
    private let healthManager = HealthKitManager.shared
    
    @State private var isSyncingWatch = true
    @State private var watchWorkoutFound = false
    
    @State private var selectedDiscipline = "RUN"
    let disciplines = ["RUN", "ROW", "SPIN", "STRENGTH"]
    
    @State private var distance: Double = 5.0
    @State private var duration: Double = 30.0
    @State private var averageHR: Double = 145.0
    @State private var rpe: Double = 6.0
    @State private var avgPower: Double = 250.0
    @State private var avgCadence: Double = 175.0
    
    // ✨ ADVANCED BIOMECHANICS
    @State private var gct: Double = 0.0
    @State private var oscillation: Double = 0.0
    @State private var elevation: Double = 0.0
    
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                Form {
                    if isSyncingWatch {
                        Section {
                            HStack {
                                ProgressView().tint(ColorTheme.prime)
                                Text("LINKING HEALTHKIT...").font(.caption.monospaced()).foregroundStyle(ColorTheme.textMuted)
                            }
                        }.listRowBackground(Color.clear)
                    }
                    
                    Section(header: Text("DISCIPLINE").font(.caption.monospaced())) {
                        Picker("Mode", selection: $selectedDiscipline) {
                            ForEach(disciplines, id: \.self) { Text($0) }
                        }.pickerStyle(.segmented).listRowBackground(Color.clear)
                    }
                    
                    Section(header: Text("KINETIC OUTPUT").font(.caption.monospaced())) {
                        if selectedDiscipline != "STRENGTH" {
                            VStack(alignment: .leading) { Text("Distance: \(distance, specifier: "%.1f") km").foregroundStyle(ColorTheme.prime); Slider(value: $distance, in: 0...42, step: 0.1) }
                            VStack(alignment: .leading) { Text("Avg Power: \(Int(avgPower)) W").foregroundStyle(.orange); Slider(value: $avgPower, in: 100...600, step: 5) }
                            VStack(alignment: .leading) { Text("Cadence: \(Int(avgCadence)) SPM").foregroundStyle(.cyan); Slider(value: $avgCadence, in: 60...210, step: 1) }
                        }
                        VStack(alignment: .leading) { Text("Duration: \(Int(duration)) min").foregroundStyle(ColorTheme.prime); Slider(value: $duration, in: 0...180, step: 1) }
                    }.listRowBackground(ColorTheme.panel)
                    
                    if selectedDiscipline == "RUN" {
                        Section(header: Text("ADVANCED TELEMETRY").font(.caption.monospaced())) {
                            VStack(alignment: .leading) { Text("GCT: \(Int(gct)) ms").foregroundStyle(.cyan); Slider(value: $gct, in: 0...400, step: 1) }
                            VStack(alignment: .leading) { Text("Oscillation: \(oscillation, specifier: "%.1f") cm").foregroundStyle(.purple); Slider(value: $oscillation, in: 0...15, step: 0.1) }
                            VStack(alignment: .leading) { Text("Elevation Gain: \(Int(elevation)) m").foregroundStyle(.green); Slider(value: $elevation, in: 0...500, step: 1) }
                        }.listRowBackground(ColorTheme.panel)
                    }
                    
                    Section(header: Text("BIOMETRIC LOAD").font(.caption.monospaced())) {
                        VStack(alignment: .leading) { Text("Avg HR: \(Int(averageHR)) BPM").foregroundStyle(ColorTheme.critical); Slider(value: $averageHR, in: 80...200, step: 1) }
                        VStack(alignment: .leading) { Text("RPE: \(Int(rpe))/10").foregroundStyle(ColorTheme.warning); Slider(value: $rpe, in: 1...10, step: 1) }
                    }.listRowBackground(ColorTheme.panel)
                    
                    Section(header: Text("DEBRIEF").font(.caption.monospaced())) {
                        TextField("Athlete Notes...", text: $notes, axis: .vertical).lineLimit(3).foregroundStyle(ColorTheme.textPrimary)
                    }.listRowBackground(ColorTheme.panel)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("LOG DIRECTIVE").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("ABORT") { dismiss() }.foregroundStyle(ColorTheme.textMuted) }
                ToolbarItem(placement: .topBarTrailing) { Button("ENGAGE") { saveSession() }.font(.caption.monospaced().bold()).foregroundStyle(ColorTheme.prime).disabled(isSyncingWatch) }
            }
            .task { await autofillFromAppleHealth() }
        }
    }
    
    // MARK: 🧠 LOGIC: AUTOFILL
    private func autofillFromAppleHealth() async {
        isSyncingWatch = true
        do {
            if let workout = try await healthManager.fetchLatestWorkout() {
                let isRide = (workout.workoutActivityType == .cycling)
                
                async let fetchedHRTask = healthManager.fetchAverageHR(for: workout)
                async let fetchedPowerTask = healthManager.fetchAveragePower(for: workout, isRide: isRide)
                async let fetchedCadenceTask = healthManager.fetchAverageCadence(for: workout, isRide: isRide)
                async let fetchedGCTTask = healthManager.fetchAverageGCT(for: workout)
                async let fetchedOscTask = healthManager.fetchAverageOscillation(for: workout)
                let fetchedElev = healthManager.fetchElevation(for: workout)
                
                let (fHR, fPower, fCad, fGCT, fOsc) = await (fetchedHRTask, fetchedPowerTask, fetchedCadenceTask, fetchedGCTTask, fetchedOscTask)
                
                await MainActor.run {
                    self.duration = workout.duration / 60.0
                    if let dist = workout.totalDistance?.doubleValue(for: .meter()) { self.distance = dist / 1000.0 }
                    
                    if fHR > 0 { self.averageHR = fHR }
                    if fPower > 0 { self.avgPower = fPower }
                    if fCad > 0 { self.avgCadence = fCad }
                    if fGCT > 0 { self.gct = fGCT }
                    if fOsc > 0 { self.oscillation = fOsc }
                    if fetchedElev > 0 { self.elevation = fetchedElev }
                    
                    switch workout.workoutActivityType {
                    case .running: self.selectedDiscipline = "RUN"
                    case .cycling: self.selectedDiscipline = "SPIN"
                    case .rowing: self.selectedDiscipline = "ROW"
                    default: break
                    }
                    self.watchWorkoutFound = true
                }
            }
        } catch {
            print("Autofill Error: \(error)")
        }
        await MainActor.run { isSyncingWatch = false }
    }
    
    // MARK: 💾 LOGIC: SAVE & LINK
    private func saveSession() {
        // ✨ MATCH TO TODAY'S MISSION
        let today = Calendar.current.startOfDay(for: .now)
        let matchedMission = allDirectives.first {
            Calendar.current.startOfDay(for: $0.date) == today
        }
        
        let newSession = KineticSession(
            date: .now,
            discipline: selectedDiscipline,
            durationMinutes: duration,
            distanceKM: selectedDiscipline == "STRENGTH" ? 0 : distance,
            averageHR: averageHR,
            rpe: Int(rpe),
            coachNotes: notes,
            avgCadence: selectedDiscipline == "STRENGTH" ? nil : avgCadence,
            avgPower: selectedDiscipline == "STRENGTH" ? nil : avgPower,
            shoeName: nil, // Shoe Logic Removed
            groundContactTime: gct > 0 ? gct : nil,
            verticalOscillation: oscillation > 0 ? oscillation : nil,
            elevationGain: elevation > 0 ? elevation : nil,
            
            // ✨ SECURE THE LINK TO THE PLAN
            linkedDirectiveID: matchedMission?.id
        )
        
        context.insert(newSession)
        try? context.save()
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
        
        Task {
            try? await healthManager.saveWorkoutToAppleHealth(
                discipline: selectedDiscipline,
                durationMinutes: duration,
                distanceKM: distance,
                averageHR: averageHR,
                notes: notes
            )
        }
    }
}
