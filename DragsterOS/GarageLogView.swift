import SwiftUI
import SwiftData

// MARK: - 🗺️ OPERATIONAL LOGBOOK (V1.2)
/// A grouped, filterable timeline of all historical kinetic sessions.
struct GarageLogView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Environment(\.modelContext) private var context
    
    // Pull all sessions, strictly ordered by newest first
    @Query(sort: \KineticSession.date, order: .reverse) private var sessions: [KineticSession]
    
    // MARK: - 🕹️ STATE MANAGEMENT
    @State private var showingAddSession = false
    @State private var editingSession: KineticSession?
    @State private var healthManager = HealthKitManager.shared
    @State private var isSyncingHistory = false
    
    // NEW: Filter State
    @State private var selectedFilter: String = "ALL"
    let filterOptions = ["ALL", "RUN", "SPIN", "STRENGTH"]
    
    // MARK: - 🧠 COMPUTED DATA
    /// Filters the main array based on the selected discipline
    private var filteredSessions: [KineticSession] {
        if selectedFilter == "ALL" { return sessions }
        return sessions.filter { $0.discipline == selectedFilter }
    }
    
    /// Groups the filtered sessions into chronological buckets (Month & Year)
    private var groupedSessions: [(month: String, sessions: [KineticSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // e.g., "April 2026"
        
        let grouped = Dictionary(grouping: filteredSessions) { session in
            formatter.string(from: session.date)
        }
        
        // Return as an array of tuples, sorted chronologically descending
        return grouped.map { (month: $0.key, sessions: $0.value.sorted(by: { $0.date > $1.date })) }
            .sorted { $0.sessions.first?.date ?? .distantPast > $1.sessions.first?.date ?? .distantPast }
    }
    
    /// Calculates the total volume (KM for cardio, Hours for strength) of the currently filtered view
    private var aggregateVolumeText: String {
        if filteredSessions.isEmpty { return "0" }
        
        if selectedFilter == "RUN" || selectedFilter == "SPIN" {
            let totalKM = filteredSessions.reduce(0) { $0 + $1.distanceKM }
            return "\(Int(totalKM)) KM TOTAL"
        } else {
            let totalMinutes = filteredSessions.reduce(0) { $0 + $1.durationMinutes }
            return "\(Int(totalMinutes / 60)) HOURS TOTAL"
        }
    }
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        VStack(spacing: 0) {
            
            // ---------------------------------------------------------
            // 1. FILTER TERMINAL
            // ---------------------------------------------------------
            VStack(spacing: 12) {
                HStack {
                    Text("TIMELINE FILTER")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                    Spacer()
                    Text(aggregateVolumeText)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                }
                
                Picker("Discipline Filter", selection: $selectedFilter) {
                    ForEach(filterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider().background(ColorTheme.surfaceBorder)
            
            // ---------------------------------------------------------
            // 2. TIMELINE DATASTREAM
            // ---------------------------------------------------------
            if filteredSessions.isEmpty {
                ContentUnavailableView(
                    "NO LOGS FOUND",
                    systemImage: "bolt.slash.fill",
                    description: Text(selectedFilter == "ALL" ? "Ingest HealthKit data or log a manual entry." : "No sessions found for \(selectedFilter).")
                )
                .foregroundStyle(ColorTheme.prime)
                .frame(maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                        
                        ForEach(groupedSessions, id: \.month) { group in
                            Section {
                                ForEach(group.sessions) { session in
                                    NavigationLink(destination: SessionDetailCanvas(session: session)) {
                                        SessionSummaryCard(session: session)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            editingSession = session
                                        }) {
                                            Label("OVERRIDE METRICS", systemImage: "slider.horizontal.3")
                                        }
                                        
                                        Button(role: .destructive, action: { deleteSingleSession(session) }) {
                                            Label("PURGE RECORD", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                // Sticky Header for the Month
                                HStack {
                                    Text(group.month.uppercased())
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                        .foregroundStyle(ColorTheme.textMuted)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(ColorTheme.background.opacity(0.95))
                                        .clipShape(Capsule())
                                    Spacer()
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                                // Prevent the background from showing underneath the sticky header
                                .background(ColorTheme.background)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 120) // Padding for floating buttons
                }
            }
        }
        .applyTacticalOS(title: "KINETIC LOGBOOK", showBack: false) // Assuming this is now a root tab
        
        // ---------------------------------------------------------
        // 3. FLOATING ACTION BUTTONS
        // ---------------------------------------------------------
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
        
        // ---------------------------------------------------------
        // 4. ROUTING MODULES
        // ---------------------------------------------------------
        .sheet(isPresented: $showingAddSession) {
            AddSessionSheet() // ✨ Connected to the new sheet we built
                .presentationDetents([.large])
        }
        .sheet(item: $editingSession) { session in
            EditSessionSheet(session: session)
        }
    }
    
    // MARK: - ⚙️ LOGIC: PURGE RECORD
    private func deleteSingleSession(_ session: KineticSession) {
        context.delete(session)
        do {
            try context.save()
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } catch {
            print("❌ DELETE FAULT: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 🧠 LOGIC: HISTORICAL SYNC
    private func ingestHistoricalData() async {
        await MainActor.run { isSyncingHistory = true }
        
        do {
            let historicalWorkouts = try await healthManager.fetchHistoricalWorkouts(daysBack: 30)
            
            let planDescriptor = FetchDescriptor<OperationalDirective>()
            let existingMissions: [OperationalDirective] = await MainActor.run {
                (try? context.fetch(planDescriptor)) ?? []
            }
            
            let existingSessionDates: [Date] = await MainActor.run {
                sessions.map { $0.date }
            }
            
            var newSessions: [KineticSession] = []
            
            for workout in historicalWorkouts {
                let alreadyExists = existingSessionDates.contains {
                    abs($0.timeIntervalSince(workout.startDate)) < 60
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
                    
                    let workoutDay = Calendar.current.startOfDay(for: workout.startDate)
                    let matchedMission = existingMissions.first {
                        Calendar.current.startOfDay(for: $0.assignedDate) == workoutDay
                    }
                    
                    async let hrTask = healthManager.fetchAverageHR(for: workout)
                    async let pwrTask = healthManager.fetchAveragePower(for: workout, isRide: isRide)
                    async let cadTask = healthManager.fetchAverageCadence(for: workout, isRide: isRide)
                    async let gctTask = healthManager.fetchAverageGCT(for: workout)
                    async let oscTask = healthManager.fetchAverageOscillation(for: workout)
                    let elevResult = healthManager.fetchElevation(for: workout)
                    
                    let (trueAvgHR, trueAvgPower, trueAvgCadence, trueGCT, trueOsc) = await (hrTask, pwrTask, cadTask, gctTask, oscTask)
                    
                    let importedSession = KineticSession(
                        date: workout.startDate,
                        discipline: discipline,
                        durationMinutes: duration,
                        distanceKM: distance,
                        averageHR: trueAvgHR,
                        rpe: 5,
                        coachNotes: "System Import: Apple Health",
                        avgCadence: trueAvgCadence > 0 ? trueAvgCadence : nil,
                        avgPower: trueAvgPower > 0 ? trueAvgPower : nil,
                        shoeName: nil,
                        groundContactTime: trueGCT > 0 ? trueGCT : nil,
                        verticalOscillation: trueOsc > 0 ? trueOsc : nil,
                        elevationGain: elevResult > 0 ? elevResult : nil,
                        linkedDirectiveID: matchedMission?.id
                    )
                    
                    newSessions.append(importedSession)
                }
            }
            
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
// MARK: - 🧱 SUB-COMPONENT: EDIT SHEET (@Bindable)
struct EditSessionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // ✨ FIXED: Sorting by .model instead of .name to match your actual schema
    @Query(sort: \RunningShoe.model) private var availableShoes: [RunningShoe]
    
    @Bindable var session: KineticSession
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("SUBJECTIVE TELEMETRY")) {
                    HStack {
                        Text("RPE (EFFORT)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        Spacer()
                        Picker("RPE", selection: $session.rpe) {
                            ForEach(1...10, id: \.self) { val in
                                Text("\(val)/10").tag(val)
                            }
                        }
                        .tint(ColorTheme.prime)
                    }
                }
                
                Section(header: Text("ATHLETE / COACH NOTES")) {
                    TextEditor(text: $session.coachNotes)
                        .frame(minHeight: 120)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                
                // ✨ FIXED: Accessing .model instead of .name
                Section(header: Text("CHASSIS DEPLOYMENT")) {
                    Picker("Select Chassis", selection: $session.shoeName) {
                        Text("NONE DEPLOYED").tag(String?.none)
                        
                        ForEach(availableShoes) { shoe in
                            // Displaying Brand + Model for clarity
                            Text("\(shoe.brand) \(shoe.model)")
                                .tag(shoe.model as String?) // We save the model string to the session
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tint(ColorTheme.prime)
                }
            }
            .applyTacticalOS(title: "OVERRIDE SESSION DATA", showBack: false)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ABORT") { dismiss() }
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.critical)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("COMMIT") {
                        try? context.save()
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        dismiss()
                    }
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.prime)
                }
            }
        }
    }
}
