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
                
                // ✨ 1. Fetch all planned missions into memory first (for speed)
                let planDescriptor = FetchDescriptor<OperationalDirective>()
                let allMissions = (try? context.fetch(planDescriptor)) ?? []
                
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
                        
                        // ✨ 2. THE MATCHMAKER: Find the mission assigned for this exact day
                        let workoutDay = Calendar.current.startOfDay(for: workout.startDate)
                        let matchedMission = allMissions.first {
                            Calendar.current.startOfDay(for: $0.date) == workoutDay
                        }
                        
                        // ✨ FETCH ALL SCALARS IN PARALLEL (Including new Biomechanics)
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
                            rpe: 5, // Subjective, defaults to 5
                            coachNotes: "System Import: Apple Health",
                            avgCadence: trueAvgCadence > 0 ? trueAvgCadence : nil,
                            avgPower: trueAvgPower > 0 ? trueAvgPower : nil,
                            shoeName: nil, // Retained as requested/from previous model
                            groundContactTime: trueGCT > 0 ? trueGCT : nil,
                            verticalOscillation: trueOsc > 0 ? trueOsc : nil,
                            elevationGain: elevResult > 0 ? elevResult : nil,
                            
                            // ✨ 3. SECURE THE LINK: Attach the UUID to the session
                            linkedDirectiveID: matchedMission?.id
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



