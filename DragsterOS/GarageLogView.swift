import SwiftUI
import SwiftData

// MARK: - 🗺️ LOGBOOK ROOT
/// The primary timeline for Dragster OS. This view manages the display of all historical
/// missions and provides the interface for manual entry and HealthKit synchronization.
struct GarageLogView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Environment(\.modelContext) private var context
    
    /// Reactive query for all completed sessions, ordered by most recent first.
    @Query(sort: \KineticSession.date, order: .reverse) private var sessions: [KineticSession]
    
    // MARK: - 🕹️ STATE MANAGEMENT
    @State private var showingAddSession = false
    @State private var healthManager = HealthKitManager.shared
    @State private var isSyncingHistory = false // Controls the loading spinner in the toolbar
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        ZStack {
            // Theme-aware background
            ColorTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: 📋 HEADER
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MISSION DEBRIEFS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        Text("KINETIC LOGBOOK")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(ColorTheme.textPrimary)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // MARK: 📜 TIMELINE
                    if sessions.isEmpty {
                        /// Standardized Empty State
                        ContentUnavailableView(
                            "NO MISSIONS LOGGED",
                            systemImage: "bolt.slash.fill",
                            description: Text("Tap the + icon to log your first completed session.")
                        )
                        .foregroundStyle(ColorTheme.prime)
                    } else {
                        /// LazyVStack ensures performance remains fluid
                        LazyVStack(spacing: 16) {
                            ForEach(sessions) { session in
                                NavigationLink(destination: SessionDetailCanvas(session: session)) {
                                    SessionSummaryCard(session: session)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // LEFT: HealthKit Historical Sync Trigger
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    Task { await ingestHistoricalData() }
                }) {
                    if isSyncingHistory {
                        ProgressView().tint(ColorTheme.prime)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                }
                .disabled(isSyncingHistory)
            }
            
            // RIGHT: Manual Mission Entry
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingAddSession = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(ColorTheme.prime)
                }
            }
        }
        .sheet(isPresented: $showingAddSession) {
            AddSessionSheet()
        }
    }
    
    // MARK: - 🧠 LOGIC: HISTORICAL SYNC (SCALARS)
    private func ingestHistoricalData() async {
        isSyncingHistory = true
        
        do {
            let historicalWorkouts = try await healthManager.fetchHistoricalWorkouts(daysBack: 30)
            var newSessions: [KineticSession] = []
            
            for workout in historicalWorkouts {
                // Anti-cloning logic
                let alreadyExists = sessions.contains {
                    abs($0.date.timeIntervalSince(workout.startDate)) < 60
                }
                
                if !alreadyExists {
                    let duration = workout.duration / 60.0
                    var distance = 0.0
                    if let dist = workout.totalDistance?.doubleValue(for: .meter()) {
                        distance = dist / 1000.0
                    }
                    
                    var discipline = "OTHER"
                    switch workout.workoutActivityType {
                    case .running: discipline = "RUN"
                    case .cycling: discipline = "SPIN"
                    case .rowing: discipline = "ROW"
                    case .traditionalStrengthTraining, .functionalStrengthTraining: discipline = "STRENGTH"
                    default: continue
                    }
                    
                    let isRide = (discipline == "SPIN")
                    
                    // ✨ THE UPGRADE: Fetch ALL Scalar Averages correctly
                    let trueAvgHR = await healthManager.fetchAverageHR(for: workout)
                    let trueAvgPower = await healthManager.fetchAveragePower(for: workout, isRide: isRide)
                    let trueAvgCadence = await healthManager.fetchAverageCadence(for: workout, isRide: isRide)
                    
                    let importedSession = KineticSession(
                        date: workout.startDate,
                        discipline: discipline,
                        durationMinutes: duration,
                        distanceKM: distance,
                        averageHR: trueAvgHR,
                        rpe: 5, // Subjective, defaults to 5
                        coachNotes: "System Import: Apple Health",
                        avgCadence: trueAvgCadence > 0 ? trueAvgCadence : nil, // Now Saved!
                        avgPower: trueAvgPower > 0 ? trueAvgPower : nil        // Now Saved!
                    )
                    
                    newSessions.append(importedSession)
                }
            }
            
            // Push UI updates back to the Main Actor
            await MainActor.run {
                if !newSessions.isEmpty {
                    for session in newSessions {
                        context.insert(session)
                    }
                    try? context.save()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
            
        } catch {
            print("❌ Sync Fault: \(error)")
        }
        
        await MainActor.run { isSyncingHistory = false }
    }
}

// MARK: - 🃏 COMPONENT: SUMMARY CARD
struct SessionSummaryCard: View {
    let session: KineticSession
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Image(systemName: session.disciplineIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(ColorTheme.background)
            }
            .frame(width: 50, height: 50)
            .background(session.disciplineColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.discipline)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(session.disciplineColor)
                    Spacer()
                    Text(session.date, format: .dateTime.month().day())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
                
                HStack(spacing: 12) {
                    if session.distanceKM > 0 {
                        Text("\(session.distanceKM, specifier: "%.1f") KM")
                    }
                    Text("\(Int(session.durationMinutes)) MIN")
                    Text("RPE \(session.rpe)/10")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(ColorTheme.textPrimary)
            }
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 🔍 VIEW: DETAIL CANVAS (VECTOR EDITION)
struct SessionDetailCanvas: View {
    let session: KineticSession
    
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    @Environment(\.dismiss) private var dismiss
    
    // ✨ NEW: JIT (Just-In-Time) Data Arrays for Charts
    @State private var healthManager = HealthKitManager.shared
    @State private var hrArray: [(Date, Double)] = []
    @State private var powerArray: [(Date, Double)] = []
    @State private var cadenceArray: [(Date, Double)] = []
    @State private var isLoadingVectors = true
    
    private var morningReadiness: Int? {
        let log = logs.first { Calendar.current.isDate($0.date, inSameDayAs: session.date) }
        return log != nil ? Int(log!.readinessScore) : nil
    }
    
    private var performanceMetric: (value: String, unit: String) {
        if session.distanceKM <= 0 { return ("-", "N/A") }
        if session.discipline == "SPIN" {
            let speed = session.distanceKM / (session.durationMinutes / 60.0)
            return (String(format: "%.1f", speed), "KM/H")
        } else {
            let pace = session.durationMinutes / session.distanceKM
            let mins = Int(pace), secs = Int((pace - Double(mins)) * 60)
            return (String(format: "%d:%02d", mins, secs), "/KM")
        }
    }

    var body: some View {
        ZStack {
            ColorTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // 1. AI EXPORT PIPELINE
                    Button(action: {
                        let excerpt = session.generateFullTacticalExcerpt(readiness: morningReadiness)
                        UIPasteboard.general.string = excerpt
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }) {
                        Label("EXPORT FULL TELEMETRY TO GEMINI", systemImage: "brain.head.profile")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.background)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(ColorTheme.prime)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // 2. HERO METRICS
                    VStack(spacing: 8) {
                        Image(systemName: session.disciplineIcon)
                            .font(.system(size: 40))
                            .foregroundStyle(session.disciplineColor)
                        Text(session.distanceKM > 0 ? "\(session.distanceKM, specifier: "%.2f") KM" : "\(Int(session.durationMinutes)) MIN")
                            .font(.system(size: 56, weight: .heavy, design: .rounded))
                            .foregroundStyle(ColorTheme.textPrimary)
                    }
                    .padding(.top, 20)

                    // 3. SCALAR GRID: KINETICS (Restored Values!)
                    HStack(spacing: 12) {
                        TelemetryBlock(title: "AVG POWER", value: session.avgPower != nil ? "\(Int(session.avgPower!))" : "-", unit: "W")
                        TelemetryBlock(title: "CADENCE", value: session.avgCadence != nil ? "\(Int(session.avgCadence!))" : "-", unit: "SPM")
                        TelemetryBlock(title: "PACE/SPD", value: performanceMetric.value, unit: performanceMetric.unit)
                    }
                    .padding(.horizontal)

                    // 4. SCALAR GRID: BIOMETRICS
                    HStack(spacing: 12) {
                        TelemetryBlock(title: "READINESS", value: morningReadiness != nil ? "\(morningReadiness!)" : "-", unit: "/100")
                        TelemetryBlock(title: "AVG HR", value: "\(Int(session.averageHR))", unit: "BPM")
                        TelemetryBlock(title: "EFFORT", value: "\(session.rpe)", unit: "/10")
                    }
                    .padding(.horizontal)

                    // ✨ 5. VECTOR CHARTS (JIT Rendered)
                    VStack(spacing: 16) {
                        if isLoadingVectors {
                            ProgressView().tint(ColorTheme.prime).padding(.vertical, 40)
                        } else {
                            if !hrArray.isEmpty {
                                TelemetryChartCard(title: "HEART RATE VECTOR", icon: "heart.fill", data: hrArray, color: ColorTheme.critical, unit: "BPM")
                            }
                            if !powerArray.isEmpty {
                                TelemetryChartCard(title: "MECHANICAL POWER", icon: "bolt.fill", data: powerArray, color: .orange, unit: "W")
                            }
                            if !cadenceArray.isEmpty {
                                TelemetryChartCard(title: "CADENCE SPARKLINE", icon: "arrow.triangle.2.circlepath", data: cadenceArray, color: .cyan, unit: "SPM")
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 6. CHASSIS / EQUIPMENT
                    if let shoe = session.shoeName {
                        Label("CHASSIS: \(shoe.uppercased())", systemImage: "shoe.2.fill")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                    }

                    // 7. ATHLETE NOTES
                    if !session.coachNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ATHLETE NOTES").font(.system(size: 12, weight: .black, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
                            Text(session.coachNotes).foregroundStyle(ColorTheme.textPrimary).italic()
                        }
                        .padding().frame(maxWidth: .infinity, alignment: .leading).background(ColorTheme.surface).clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .task {
            // ✨ THE JIT TRIGGER: Fetch the raw arrays exactly when the user opens the canvas
            let isRide = session.discipline == "SPIN"
            async let fetchedHR = healthManager.fetchHRSeries(start: session.date, durationMinutes: session.durationMinutes)
            async let fetchedPower = healthManager.fetchPowerSeries(start: session.date, durationMinutes: session.durationMinutes, isRide: isRide)
            async let fetchedCadence = healthManager.fetchCadenceSeries(start: session.date, durationMinutes: session.durationMinutes, isRide: isRide)
            
            let (hrRes, pwrRes, cadRes) = await (fetchedHR, fetchedPower, fetchedCadence)
            
            await MainActor.run {
                self.hrArray = hrRes
                self.powerArray = pwrRes
                self.cadenceArray = cadRes
                self.isLoadingVectors = false
            }
        }
    }
}

// MARK: - 📦 COMPONENT: TELEMETRY BLOCK
struct TelemetryBlock: View {
    let title: String, value: String, unit: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
            Text(value).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(ColorTheme.textPrimary)
            Text(unit).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).background(ColorTheme.surface).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 📝 SHEET: HYBRID INPUT
struct AddSessionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RunningShoe.brand) private var inventory: [RunningShoe]
    @State private var healthManager = HealthKitManager.shared
    
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
    @State private var selectedShoe: RunningShoe?
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                Form {
                    if isSyncingWatch {
                        Section {
                            HStack { ProgressView().tint(ColorTheme.prime); Text("LINKING HEALTHKIT...").font(.caption.monospaced()).foregroundStyle(ColorTheme.textMuted) }
                        }.listRowBackground(Color.clear)
                    }
                    
                    Section(header: Text("DISCIPLINE").font(.caption.monospaced())) {
                        Picker("Mode", selection: $selectedDiscipline) { ForEach(disciplines, id: \.self) { Text($0) } }.pickerStyle(.segmented).listRowBackground(Color.clear)
                    }
                    
                    Section(header: Text("KINETIC OUTPUT").font(.caption.monospaced())) {
                        if selectedDiscipline != "STRENGTH" {
                            VStack(alignment: .leading) { Text("Distance: \(distance, specifier: "%.1f") km").foregroundStyle(ColorTheme.prime); Slider(value: $distance, in: 0...42, step: 0.1) }
                            VStack(alignment: .leading) { Text("Avg Power: \(Int(avgPower)) W").foregroundStyle(.orange); Slider(value: $avgPower, in: 100...600, step: 5) }
                            VStack(alignment: .leading) { Text("Cadence: \(Int(avgCadence)) SPM").foregroundStyle(.cyan); Slider(value: $avgCadence, in: 60...210, step: 1) }
                        }
                        VStack(alignment: .leading) { Text("Duration: \(Int(duration)) min").foregroundStyle(ColorTheme.prime); Slider(value: $duration, in: 0...180, step: 1) }
                    }.listRowBackground(ColorTheme.panel)
                    
                    Section(header: Text("BIOMETRIC LOAD").font(.caption.monospaced())) {
                        VStack(alignment: .leading) { Text("Avg HR: \(Int(averageHR)) BPM").foregroundStyle(ColorTheme.critical); Slider(value: $averageHR, in: 80...200, step: 1) }
                        VStack(alignment: .leading) { Text("RPE: \(Int(rpe))/10").foregroundStyle(ColorTheme.warning); Slider(value: $rpe, in: 1...10, step: 1) }
                    }.listRowBackground(ColorTheme.panel)
                    
                    if selectedDiscipline == "RUN" {
                        Section(header: Text("CHASSIS (SHOES)").font(.caption.monospaced())) {
                            Picker("Active Shoe", selection: $selectedShoe) {
                                Text("NO SHOE SELECTED").tag(nil as RunningShoe?)
                                // ✨ ALIAS FIX
                                ForEach(inventory) { shoe in Text(shoe.name).tag(shoe as RunningShoe?) }
                            }.tint(ColorTheme.prime)
                        }.listRowBackground(ColorTheme.panel)
                    }
                    
                    Section(header: Text("DEBRIEF").font(.caption.monospaced())) {
                        TextField("Athlete Notes...", text: $notes, axis: .vertical).lineLimit(3).foregroundStyle(ColorTheme.textPrimary)
                    }.listRowBackground(ColorTheme.panel)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("LOG MISSION").navigationBarTitleDisplayMode(.inline)
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
        if let workout = try? await healthManager.fetchLatestWorkout() {
            
            let isRide = (workout.workoutActivityType == .cycling)
            // ✨ THE FIX: Fetch ALL Scalars for the manual input sliders
            let fetchedHR = await healthManager.fetchAverageHR(for: workout)
            let fetchedPower = await healthManager.fetchAveragePower(for: workout, isRide: isRide)
            let fetchedCadence = await healthManager.fetchAverageCadence(for: workout, isRide: isRide)
            
            await MainActor.run {
                self.duration = workout.duration / 60.0
                if let dist = workout.totalDistance?.doubleValue(for: .meter()) { self.distance = dist / 1000.0 }
                
                if fetchedHR > 0 { self.averageHR = fetchedHR }
                if fetchedPower > 0 { self.avgPower = fetchedPower }
                if fetchedCadence > 0 { self.avgCadence = fetchedCadence }
                
                switch workout.workoutActivityType {
                case .running: self.selectedDiscipline = "RUN"
                case .cycling: self.selectedDiscipline = "SPIN"
                case .rowing: self.selectedDiscipline = "ROW"
                default: break
                }
                self.watchWorkoutFound = true
            }
        }
        await MainActor.run { isSyncingWatch = false }
    }
    
    private func saveSession() {
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
            shoeName: selectedShoe?.name
        )
        if let shoe = selectedShoe, selectedDiscipline == "RUN" { shoe.currentMileage += distance }
        context.insert(newSession)
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success); dismiss()
    }
}
