import SwiftUI
import SwiftData

// MARK: - 🗺️ OPERATIONAL LOGBOOK
struct GarageLogView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Environment(\.modelContext) private var context
    
    /// Reactive query for all completed sessions, ordered by most recent first.
    @Query(sort: \KineticSession.date, order: .reverse) private var sessions: [KineticSession]
    
    // MARK: - 🕹️ STATE MANAGEMENT
    @State private var showingAddSession = false
    @State private var editingSession: KineticSession?
    @State private var healthManager = HealthKitManager.shared
    @State private var isSyncingHistory = false
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: 📜 TIMELINE
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "NO DIRECTIVES ANALYZED",
                        systemImage: "bolt.slash.fill",
                        description: Text("Ingest HealthKit data or log a manual entry.")
                    )
                    .foregroundStyle(ColorTheme.prime)
                    .padding(.top, 100)
                } else {
                    // ✨ REVERTED: Back to high-performance LazyVStack
                    LazyVStack(spacing: 16) {
                        ForEach(sessions) { session in
                            NavigationLink(destination: SessionDetailCanvas(session: session)) {
                                SessionSummaryCard(session: session)
                            }
                            .buttonStyle(PlainButtonStyle())
                            // ✨ NEW: Context Menu for Edit/Delete (Fixes the Navigation Bug)
                            .contextMenu {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    editingSession = session
                                }) {
                                    Label("OVERRIDE METRICS", systemImage: "slider.horizontal.3")
                                }
                                
                                Button(role: .destructive, action: {
                                    deleteSingleSession(session)
                                }) {
                                    Label("PURGE RECORD", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 20)
            .padding(.bottom, 100) // Padding for floating buttons
        }
        .applyTacticalOS(title: "KINETIC LOGBOOK", showBack: true)
        
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
            Text("ADD SESSION SHEET GOES HERE").presentationDetents([.medium])
        }
        .sheet(item: $editingSession) { session in
            EditSessionSheet(session: session)
        }
    }
    
    // MARK: - ⚙️ LOGIC: PURGE RECORD (Context Menu Version)
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
                        Calendar.current.startOfDay(for: $0.date) == workoutDay
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
                
                Section(header: Text("CHASSIS DEPLOYMENT")) {
                    TextField("Shoe Name", text: Binding(
                        get: { session.shoeName ?? "" },
                        set: { session.shoeName = $0 }
                    ))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
            }
            .applyTacticalOS(title: "OVERRIDE SESSION DATA", showBack: false)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
