import SwiftUI
import SwiftData

// MARK: - 🗺️ THE COMMAND CENTER
struct ContentView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Environment(\.modelContext) private var context
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    @Query(sort: \KineticSession.date, order: .forward) private var sessions: [KineticSession]
    
    // ✨ NEW: Query the macro-cycle to pull today's Fuel Tier
    @Query(sort: \OperationalDirective.date, order: .forward) private var missions: [OperationalDirective]
    
    private var healthManager = HealthKitManager.shared
    @State private var alertManager = SystemAlertManager.shared
    
    // MARK: - 🕹️ STATE
    @State private var isSyncing: Bool = true
    @State private var showingManualOverride: Bool = false
    
    // MARK: - 🧠 COMPUTED TELEMETRY
    private var todayLog: TelemetryLog? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) })
    }
    
    private var todayMission: OperationalDirective? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return missions.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) })
    }
    
    private var readiness: Double { todayLog?.readinessScore ?? 0.0 }
    private var hrv: Double { todayLog?.hrv ?? 0.0 }
    private var rhr: Double { todayLog?.restingHR ?? 0.0 }
    private var sleep: Double { todayLog?.sleepDuration ?? 0.0 }
    private var weight: Double { todayLog?.weightKG ?? 0.0 }
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    ObjectiveWidget()
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // ✨ THERMODYNAMIC FUEL GAUGE (Macro & Calorie Tracking)
                    ThermodynamicFuelWidget(
                        plannedTier: todayMission?.fuelTier,
                        currentWeightKG: weight > 0 ? weight : 80.0 // Fallback to 80kg if unlogged
                    )
                    .padding(.horizontal)
                    
                    // ✨ THERMODYNAMIC FUEL GAUGE (Shows Today's progress)
                                  EnergyBalanceWidget()
                                      .padding(.horizontal)
                    
                    
                    ReadinessTrendChart(logs: logs)
                        .padding(.horizontal)
                    
                    // MORNING TELEMETRY
                    VStack(spacing: 16) {
                        HStack {
                            Text("MORNING TELEMETRY")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            Spacer()
                            
                            if isSyncing {
                                ProgressView().tint(ColorTheme.prime)
                            } else {
                                Button(action: { showingManualOverride = true }) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 14))
                                        .foregroundStyle(ColorTheme.prime)
                                }
                            }
                        }
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                BiometricMiniCard(title: "HRV", value: hrv > 0 ? "\(Int(hrv))" : "-", unit: "MS", color: .cyan)
                                BiometricMiniCard(title: "RHR", value: rhr > 0 ? "\(Int(rhr))" : "-", unit: "BPM", color: ColorTheme.critical)
                            }
                            HStack(spacing: 12) {
                                BiometricMiniCard(title: "SLEEP", value: sleep > 0 ? String(format: "%.1f", sleep) : "-", unit: "HRS", color: .purple)
                                BiometricMiniCard(title: "MASS", value: weight > 0 ? String(format: "%.1f", weight) : "-", unit: "KG", color: .orange)
                            }
                        }
                        
                        ReadinessBatteryBar(score: readiness)
                    }
                    .padding(.horizontal)
                    
                    Divider().background(ColorTheme.surfaceBorder).padding(.horizontal)
                    
                    // CORE MODULES
                    VStack(spacing: 12) {
                        Text("CORE MODULES")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        NavigationLink(destination: OperationalBriefingView()) {
                            DashboardMenuButton(title: "TACTICAL BRIEFING", icon: "list.clipboard.fill", color: ColorTheme.prime)
                        }
                        
                        // ✨ NEW: The door to your Strategic Objectives
                        NavigationLink(destination: StrategicObjectivesView()) {
                            DashboardMenuButton(title: "STRATEGIC OBJECTIVES", icon: "scope", color: ColorTheme.critical)
                        }
                        
                        NavigationLink(destination: AIBriefingView()) {
                            DashboardMenuButton(title: "AI BRIEFING", icon: "cpu", color: ColorTheme.prime)
                        }
                        
                        NavigationLink(destination: GarageLogView()) {
                            DashboardMenuButton(title: "KINETIC LOGBOOK", icon: "bolt.fill", color: ColorTheme.warning)
                        }
                        NavigationLink(destination: MacroCycleView()) {
                            DashboardMenuButton(title: "MACRO-CYCLE STRATEGY", icon: "calendar.badge.clock", color: .purple)
                        }
                        NavigationLink(destination: ChassisCommandView()) {
                            DashboardMenuButton(title: "CHASSIS & EFFICIENCY", icon: "gauge.with.needle.fill", color: .cyan)
                        }
                        NavigationLink(destination: EquipmentInventoryView()) {
                            DashboardMenuButton(title: "EQUIPMENT INVENTORY", icon: "shoe.2.fill", color: .orange)
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: purgeDatabase) {
                        Text("FACTORY RESET: PURGE DATA CACHE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.critical.opacity(0.6))
                            .padding(.vertical, 20)
                    }
                }
            }
            .applyTacticalOS(title: "COMMAND CENTER", showBack: false)
            .task { await bootSystem() }
            .sheet(isPresented: $showingManualOverride) {
                ManualTelemetrySheet(log: todayLog, history: logs)
            }
        }
    }
    
    // MARK: - ⚙️ LOGIC: BOOT SEQUENCE
    
    private func bootSystem() async {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            await alertManager.requestAuthorization()
            try await healthManager.requestAuthorization()
            
            // 1. Ensure Macro-Cycle exists
            let planDescriptor = FetchDescriptor<OperationalDirective>()
            let existingMissions = (try? context.fetch(planDescriptor)) ?? []
            if existingMissions.isEmpty {
                let parsedMissions = CSVParserEngine.generateMacroCycle()
                await MainActor.run {
                    for mission in parsedMissions { context.insert(mission) }
                    try? context.save()
                }
            }
            
            // 2. Calculate Current Mechanical Load Profile
            let currentLoadProfile = LoadEngine.computeCurrentLoad(history: sessions)
            
            // 3. HISTORICAL BACKFILL
            if logs.count < 2 {
                let historyData = await healthManager.fetchHistoricalBiometrics(daysBack: 60)
                let sortedData = historyData.sorted { $0.date < $1.date }
                
                await MainActor.run {
                    var rollingHistory: [TelemetryLog] = []
                    for bio in sortedData {
                        let newLog = TelemetryLog(
                            date: bio.date,
                            hrv: bio.hrv,
                            restingHR: bio.restingHR,
                            sleepDuration: bio.sleepHours,
                            weightKG: 0.0,
                            readinessScore: 0.0
                        )
                        newLog.readinessScore = ReadinessEngine.computeReadiness(
                            todayLog: newLog,
                            history: rollingHistory,
                            loadProfile: LoadEngine.LoadProfile(ctl: 0, atl: 0)
                        )
                        context.insert(newLog)
                        rollingHistory.insert(newLog, at: 0)
                    }
                    try? context.save()
                }
            }
            
            // 4. FETCH TODAY'S LIVE DATA
            let metrics = try await healthManager.fetchMorningReadiness()
            let latestWeight = try await healthManager.fetchLatestWeight()
            
            let descriptor = FetchDescriptor<TelemetryLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let updatedLogs = (try? context.fetch(descriptor)) ?? logs
            
            // 5. PERSIST TODAY'S LOG
            await MainActor.run {
                let currentReadiness: Double
                
                if let existingLog = todayLog {
                    if metrics.hrv > 0 && existingLog.rmssd == nil { existingLog.hrv = metrics.hrv }
                    if metrics.restingHR > 0 { existingLog.restingHR = metrics.restingHR }
                    if metrics.sleepHours > 0 { existingLog.sleepDuration = metrics.sleepHours }
                    if latestWeight > 0 { existingLog.weightKG = latestWeight }
                    
                    existingLog.readinessScore = ReadinessEngine.computeReadiness(
                        todayLog: existingLog,
                        history: updatedLogs,
                        loadProfile: currentLoadProfile
                    )
                    currentReadiness = existingLog.readinessScore
                } else {
                    let newLog = TelemetryLog(
                        date: Calendar.current.startOfDay(for: .now),
                        hrv: metrics.hrv,
                        restingHR: metrics.restingHR,
                        sleepDuration: metrics.sleepHours,
                        weightKG: latestWeight,
                        readinessScore: 0.0
                    )
                    
                    newLog.readinessScore = ReadinessEngine.computeReadiness(
                        todayLog: newLog,
                        history: updatedLogs,
                        loadProfile: currentLoadProfile
                    )
                    
                    context.insert(newLog)
                    currentReadiness = newLog.readinessScore
                }
                try? context.save()
                
                alertManager.evaluatePhysiologicalLoad(currentReadiness: currentReadiness)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
        } catch {
            print("❌ Boot Fault: \(error.localizedDescription)")
        }
    }
    
    private func purgeDatabase() {
        do {
            try context.delete(model: TelemetryLog.self)
            try context.delete(model: KineticSession.self)
            try context.delete(model: OperationalDirective.self)
            try context.delete(model: StrategicObjective.self)
            try context.delete(model: ChassisLog.self)
            try context.delete(model: RunningShoe.self)
            try context.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("❌ PURGE FAULT: \(error.localizedDescription)")
        }
    }
}
