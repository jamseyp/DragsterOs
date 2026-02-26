import SwiftUI
import SwiftData

// MARK: - 🗺️ OPERATIONAL LOGBOOK
/// The primary timeline for Dragster OS. This view manages the display of all historical
/// directives and provides the interface for manual entry and HealthKit synchronization.
struct GarageLogView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Environment(\.modelContext) private var context
    
    /// Reactive query for all completed sessions, ordered by most recent first.
    @Query(sort: \KineticSession.date, order: .reverse) private var sessions: [KineticSession]
    
    // MARK: - 🕹️ STATE MANAGEMENT
    @State private var showingAddSession = false
    @State private var healthManager = HealthKitManager.shared
    @State private var isSyncingHistory = false
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: 📜 TIMELINE
                if sessions.isEmpty {
                    /// Standardized Empty State
                    ContentUnavailableView(
                        "NO DIRECTIVES ANALYZED",
                        systemImage: "bolt.slash.fill",
                        description: Text("Ingest HealthKit data or log a manual entry.")
                    )
                    .foregroundStyle(ColorTheme.prime)
                    .padding(.top, 100)
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
            .padding(.vertical, 20)
            .padding(.bottom, 100) // Padding for floating buttons
        }
        // ✨ THE OS WRAPPER: Handles background, header, and hides system nav
        .applyTacticalOS(title: "KINETIC LOGBOOK")
        
        // ✨ FLOATING TACTICAL OVERLAYS
        .overlay(alignment: .bottomTrailing) {
            TacticalActionButton(icon: "plus", color: ColorTheme.prime) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingAddSession = true
            }
            .padding(24)
        }
        .overlay(alignment: .bottomLeading) {
            TacticalActionButton(icon: "arrow.triangle.2.circlepath", color: ColorTheme.textMuted) {
                Task { await ingestHistoricalData() }
            }
            .padding(24)
            .opacity(isSyncingHistory ? 0.5 : 1.0)
            .disabled(isSyncingHistory)
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
                    
                    // Fetch ALL Scalar Averages correctly
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
                        avgCadence: trueAvgCadence > 0 ? trueAvgCadence : nil,
                        avgPower: trueAvgPower > 0 ? trueAvgPower : nil
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
    
    // MARK: - 🧠 AEROBIC DECOUPLING ENGINE
    private var aerobicDecoupling: Double? {
        guard hrArray.count > 20, powerArray.count > 20 else { return nil }
        
        let sortedHR = hrArray.sorted { $0.0 < $1.0 }
        let sortedPower = powerArray.sorted { $0.0 < $1.0 }
        
        let midHR = sortedHR.count / 2
        let midPower = sortedPower.count / 2
        
        let hrFirstHalf = sortedHR[0..<midHR].map { $0.1 }.reduce(0, +) / Double(midHR)
        let hrSecondHalf = sortedHR[midHR...].map { $0.1 }.reduce(0, +) / Double(sortedHR.count - midHR)
        
        let pwrFirstHalf = sortedPower[0..<midPower].map { $0.1 }.reduce(0, +) / Double(midPower)
        let pwrSecondHalf = sortedPower[midPower...].map { $0.1 }.reduce(0, +) / Double(sortedPower.count - midPower)
        
        guard hrFirstHalf > 0, hrSecondHalf > 0 else { return nil }
        
        let efFirstHalf = pwrFirstHalf / hrFirstHalf
        let efSecondHalf = pwrSecondHalf / hrSecondHalf
        
        return ((efFirstHalf - efSecondHalf) / efFirstHalf) * 100.0
    }
    
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
    
    // MARK: 🧠 HR ZONE ENGINE
    private var hrZones: [(zone: String, time: Double, color: Color)] {
        guard !hrArray.isEmpty else { return [] }
        
        var z1 = 0.0, z2 = 0.0, z3 = 0.0, z4 = 0.0, z5 = 0.0
        let sorted = hrArray.sorted { $0.0 < $1.0 }
        
        for i in 0..<(sorted.count - 1) {
            let bpm = sorted[i].1
            let duration = sorted[i+1].0.timeIntervalSince(sorted[i].0)
            let validDuration = min(duration, 10.0)
            
            switch bpm {
            case ..<133: z1 += validDuration
            case 133..<152: z2 += validDuration
            case 152..<171: z3 += validDuration
            case 171..<185: z4 += validDuration
            default: z5 += validDuration
            }
        }
        
        return [
            ("Z1", z1 / 60.0, .gray),
            ("Z2", z2 / 60.0, .cyan),
            ("Z3", z3 / 60.0, .green),
            ("Z4", z4 / 60.0, .orange),
            ("Z5", z5 / 60.0, ColorTheme.critical)
        ].filter { $0.1 > 0 }
    }
    
    var body: some View {
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
                .padding(.top, 20)
                
                // 2. HERO METRICS
                VStack(spacing: 8) {
                    Image(systemName: session.disciplineIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(session.disciplineColor)
                    Text(session.distanceKM > 0 ? "\(session.distanceKM, specifier: "%.2f") KM" : "\(Int(session.durationMinutes)) MIN")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                // 3. SCALAR GRID: KINETICS
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
                        
                        // ✨ AEROBIC DECOUPLING METRIC
                        if let decoupling = aerobicDecoupling {
                            let isEfficient = decoupling <= 5.0 // < 5% drift is considered highly fit
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("AEROBIC DECOUPLING (Pa:Hr)")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textMuted)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", decoupling))
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundStyle(isEfficient ? .green : ColorTheme.critical)
                                    
                                    Text("%")
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                        .foregroundStyle(isEfficient ? .green : ColorTheme.critical)
                                    
                                    Spacer()
                                    
                                    Image(systemName: isEfficient ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(isEfficient ? .green : ColorTheme.critical)
                                }
                                
                                Text(isEfficient
                                     ? "Optimal aerobic efficiency maintained. Cardiovascular drift was kept under the 5% threshold."
                                     : "Cardiovascular drift detected. Your base endurance is currently lacking for this specific duration/intensity.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(ColorTheme.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                // Contextual Guardrail
                                Text("⚠️ METRIC ONLY VALID FOR STEADY-STATE / ZONE 2 EFFORTS. IGNORE FOR INTERVALS.")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundStyle(ColorTheme.warning)
                                    .padding(.top, 4)
                            }
                            .padding(20)
                            .background(ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // ✨ TIME IN ZONES
                        if !hrZones.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TIME IN ZONES").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
                                
                                HStack(spacing: 4) {
                                    ForEach(hrZones, id: \.zone) { zone in
                                        VStack(spacing: 4) {
                                            Text("\(Int(zone.time))m")
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                .foregroundStyle(ColorTheme.textPrimary)
                                            
                                            Rectangle()
                                                .fill(zone.color)
                                                .frame(height: 6)
                                                .clipShape(Capsule())
                                            
                                            Text(zone.zone)
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundStyle(ColorTheme.textMuted)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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
        // ✨ OS WRAPPER APPLIED HERE
        .applyTacticalOS(title: "DIRECTIVE ANALYSIS")
        
        // ✨ CUSTOM BACK BUTTON (Since navigation bar is hidden)
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ColorTheme.prime)
                    .padding()
            }
        }
        .task {
            // ✨ THE JIT TRIGGER
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

// MARK: - 🔘 COMPONENT: TACTICAL ACTION BUTTON
struct TacticalActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(ColorTheme.background)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 10)
        }
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
        if let workout = try? await healthManager.fetchLatestWorkout() {
            
            let isRide = (workout.workoutActivityType == .cycling)
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
