import SwiftUI
import SwiftData

// MARK: - 🗺️ ROOT TAB CONTROLLER
/// This is the new primary entry point of Dragster OS.
/// It initializes the system, fetches all necessary data, and distributes it across four distinct tabs.
struct ContentView: View {
    
    // MARK: - 🗄️ PERSISTENCE (GLOBAL)
    // Global queries passed down to sub-views to maintain a single source of truth.
    @Environment(\.modelContext) private var context
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    @Query(sort: \KineticSession.date, order: .forward) private var sessions: [KineticSession]
    @Query(sort: \OperationalDirective.assignedDate, order: .forward) private var missions: [OperationalDirective]
    
    // Global Managers
    private var healthManager = HealthKitManager.shared
    @State private var alertManager = SystemAlertManager.shared
    
    // MARK: - 🕹️ SYSTEM STATE
    @State private var isSyncing: Bool = true
    @State private var showingManualOverride: Bool = false
    @State private var activeTab: Int = 0 // Tracks the currently active tactical tab
    
    // MARK: - 🖼️ UI BODY
    var body: some View {
        TabView(selection: $activeTab) {
            
            // ---------------------------------------------------------
            // 🟢 TAB 1: COMMAND CENTER (Today's Live Telemetry)
            // ---------------------------------------------------------
            NavigationStack {
                DashboardTab(
                    isSyncing: $isSyncing,
                    showingManualOverride: $showingManualOverride,
                    logs: logs,
                    missions: missions
                )
            }
            .tabItem {
                Label("COMMAND", systemImage: "target")
            }
            .tag(0)
            
            // ---------------------------------------------------------
            // ⚡️ TAB 2: KINETICS (Historical Garage Log)
            // ---------------------------------------------------------
            NavigationStack {
                GarageLogView()
            }
            .tabItem {
                Label("KINETICS", systemImage: "bolt.fill")
            }
            .tag(1)
            
            // ---------------------------------------------------------
            // 🗓️ TAB 3: STRATEGY (Planning & Logistics)
            // ---------------------------------------------------------
            NavigationStack {
                StrategyHubTab()
            }
            .tabItem {
                Label("STRATEGY", systemImage: "calendar.badge.clock")
            }
            .tag(2)
            
            // ---------------------------------------------------------
            // 🧠 TAB 4: INTELLIGENCE (AI & Baselines)
            // ---------------------------------------------------------
            NavigationStack {
                IntelligenceHubTab()
            }
            .tabItem {
                Label("INTEL", systemImage: "cpu")
            }
            .tag(3)
        }
        .tint(ColorTheme.prime) // Forces the active tab to use the Dragster OS primary color
        .task {
            // Boot sequence runs once when the app is launched
            await bootSystem()
        }
        .sheet(isPresented: $showingManualOverride) {
            // Manual override isolated here, triggered from the DashboardTab
            let todayLog = logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: .now) })
            ManualTelemetrySheet(log: todayLog, history: logs)
        }
    }
    
    // MARK: - ⚙️ LOGIC: BOOT SEQUENCE
    /// Handles authorization, empty database seeding, and daily metric updates.
    private func bootSystem() async {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            await alertManager.requestAuthorization()
            try await healthManager.requestAuthorization()
            
            // 1. Ensure Macro-Cycle exists (Seed empty DB)
            let planDescriptor = FetchDescriptor<OperationalDirective>()
            let existingMissions = (try? context.fetch(planDescriptor)) ?? []
            if existingMissions.isEmpty {
                let parsedMissions = CSVParserEngine.generateMacroCycle()
                await MainActor.run {
                    for mission in parsedMissions { context.insert(mission) }
                    try? context.save()
                }
            }
            
            // 2. Calculate Current Mechanical Load Profile (ATL/CTL)
            let currentLoadProfile = LoadEngine.computeCurrentLoad(history: sessions)
            
            // 3. Historical Backfill (If less than 2 logs exist)
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
            
            // 4. Fetch Today's Live Apple Health Data
            let metrics = try await healthManager.fetchMorningReadiness()
            let latestWeight = try await healthManager.fetchLatestWeight()
            
            // Refresh logs array before computing today's readiness
            let descriptor = FetchDescriptor<TelemetryLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let updatedLogs = (try? context.fetch(descriptor)) ?? logs
            
            // 5. Persist Today's Log & Compute Readiness
            await MainActor.run {
                let currentReadiness: Double
                let todayLog = updatedLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: .now) })
                
                if let existingLog = todayLog {
                    // Update existing, respecting RMSSD manual override
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
                    // Create new log
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
                
                // Trigger warning notification if fatigued
                alertManager.evaluatePhysiologicalLoad(currentReadiness: currentReadiness)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
        } catch {
            print("❌ Boot Fault: \(error.localizedDescription)")
        }
    }
}

// MARK: - 🟢 SUB-VIEW: DASHBOARD TAB
/// Handles the immediate operational requirements: Mission, Fuel, and Readiness.
struct DashboardTab: View {
    @Binding var isSyncing: Bool
    @Binding var showingManualOverride: Bool
    var logs: [TelemetryLog]
    var missions: [OperationalDirective]
    
    private var todayLog: TelemetryLog? {
        logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: .now) })
    }
    private var todayMission: OperationalDirective? {
        missions.first(where: { Calendar.current.isDate($0.assignedDate, inSameDayAs: .now) })
    }
    
    // Computed values for clean UI mapping
    private var readiness: Double { todayLog?.readinessScore ?? 0.0 }
    private var hrv: Double { todayLog?.hrv ?? 0.0 }
    private var rhr: Double { todayLog?.restingHR ?? 0.0 }
    private var sleep: Double { todayLog?.sleepDuration ?? 0.0 }
    private var weight: Double { todayLog?.weightKG ?? 0.0 }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // 1. Current Strategic Target
                NavigationLink(destination: StrategicObjectivesView()) {
                    ObjectiveWidget()
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.top, 20)
                
                // 2. Thermodynamic Requirements based on Mission Tier
                ThermodynamicFuelWidget(
                    plannedTier: todayMission?.fuelTier,
                    currentWeightKG: weight > 0 ? weight : 80.0
                )
                .padding(.horizontal)
                
                // .3 Energy Balance
                EnergyBalanceWidget()
                    .padding(.horizontal)
                
                // 3. Visual 7-Day Readiness
                ReadinessTrendChart(logs: logs)
                    .padding(.horizontal)
                
                // 4. Daily Biometrics Grid
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
                    .padding(.bottom, 20)
            }
        }
        .applyTacticalOS(title: "COMMAND CENTER", showBack: false)
    }
}

// MARK: - 🗓️ SUB-VIEW: STRATEGY HUB TAB
/// Centralizes forward-looking logistics (Macro-cycle, Chassis tracking, Objectives).
struct StrategyHubTab: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                Text("LOGISTICS & PLANNING")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                
                NavigationLink(destination: OperationsHubView()) {
                    DashboardMenuButton(title: "Training Plan", icon: "calendar.badge.clock", color: .purple)
                }
                
                
                
                NavigationLink(destination: StrategicObjectivesView()) {
                    DashboardMenuButton(title: "Goals", icon: "scope", color: ColorTheme.critical)
                }
                
                NavigationLink(destination: EquipmentInventoryView()) {
                    DashboardMenuButton(title: "Shoes", icon: "shoe.2.fill", color: ColorTheme.caution)
                }
                
                NavigationLink(destination: ChassisCommandView()) {
                    DashboardMenuButton(title: "Body Measurements & Peak Power", icon: "gauge.with.needle.fill", color: ColorTheme.optimal)
                }
            }
            .padding(.horizontal)
        }
        .applyTacticalOS(title: "STRATEGY COMMAND", showBack: false)
    }
}

// MARK: - 🧠 SUB-VIEW: INTELLIGENCE HUB TAB
/// Houses the analytical components of the OS (AI, Briefings, Baseline metrics).
struct IntelligenceHubTab: View {
    @Environment(\.modelContext) private var context
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                Text("ANALYSIS & AI SYSTEMS")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                
                NavigationLink(destination: OperationalBriefingView()) {
                    DashboardMenuButton(title: "TACTICAL BRIEFING", icon: "list.clipboard.fill", color: ColorTheme.prime)
                }
                
                NavigationLink(destination: AIBriefingView()) {
                    DashboardMenuButton(title: "GEMINI INTELLIGENCE", icon: "cpu", color: .cyan)
                }
                
                NavigationLink(destination: BiometricBaselineView()) {
                    DashboardMenuButton(title: "SYSTEM BASELINES", icon: "waveform.path.ecg", color: .green)
                }
            }
            .padding(.horizontal)
            
            // Factory Reset moved here to prevent accidental triggering on the main dashboard
            Button(action: purgeDatabase) {
                Text("FACTORY RESET: PURGE DATA CACHE")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.critical.opacity(0.6))
                    .padding(.vertical, 40)
            }
        }
        .applyTacticalOS(title: "INTELLIGENCE", showBack: false)
    }
    
    // Core Data purge logic
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
