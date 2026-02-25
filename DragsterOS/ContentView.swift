import SwiftUI
import SwiftData

// MARK: - 🗺️ THE COMMAND CENTER
/// The primary operational dashboard. Orchestrates HealthKit ingestion and routes to subsystems.
struct ContentView: View {
    
    // MARK: - 🗄️ PERSISTENCE
    @Environment(\.modelContext) private var context
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    @State private var healthManager = HealthKitManager.shared
    @State private var alertManager = SystemAlertManager.shared
    
    // MARK: - 🕹️ STATE
    @State private var isSyncing: Bool = true
    @State private var showingManualOverride: Bool = false
    
    // MARK: - 🧠 COMPUTED TELEMETRY
    private var todayLog: TelemetryLog? {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) })
    }
    
    private var readiness: Double { todayLog?.readinessScore ?? 0.0 }
    private var hrv: Double { todayLog?.hrv ?? 0.0 }
    private var rhr: Double { todayLog?.restingHR ?? 0.0 }
    private var sleep: Double { todayLog?.sleepDuration ?? 0.0 }
    private var weight: Double { todayLog?.weightKG ?? 0.0 }
    
    // MARK: - 🖼️ UI BODY
    
    var body: some View {
            NavigationStack {
                ZStack {
                    ColorTheme.background.ignoresSafeArea()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            // 1. TOP HEADER
                            TacticalStatusHeader()
                            
                            // ✨ 2. THE NEW MACRO-CYCLE CHART ✨
                            // We pass the full SwiftData 'logs' array; the component handles the sorting/filtering
                            ReadinessTrendChart(logs: logs)
                                .padding(.horizontal)
                            
                            // 3. BIOMETRIC GRID
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
                                
                                // Extracted Component Grid
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
                                
                                // Extracted Component Battery Bar
                                ReadinessBatteryBar(score: readiness)
                            }
                            .padding(.horizontal)
                            
                            Divider().background(ColorTheme.surfaceBorder).padding(.horizontal)
                            
                            // 4. SYSTEM ROUTING
                            VStack(spacing: 12) {
                                Text("CORE MODULES")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                NavigationLink(destination: MissionView()) {
                                    DashboardMenuButton(title: "TACTICAL BRIEFING", icon: "list.clipboard.fill", color: ColorTheme.prime)
                                }
                                NavigationLink(destination: GarageLogView()) {
                                    DashboardMenuButton(title: "KINETIC LOGBOOK", icon: "bolt.fill", color: ColorTheme.warning)
                                }
                                
                                // ✨ ADD THIS NEW ROUTE:
                                NavigationLink(destination: MacroCycleView()) {
                                    DashboardMenuButton(title: "MACRO-CYCLE STRATEGY", icon: "calendar.grid.3x3.fill", color: .purple)
                                }
                                
                                NavigationLink(destination: ChassisView()) {
                                    DashboardMenuButton(title: "MASS & EFFICIENCY", icon: "scalemass.fill", color: ColorTheme.recovery)
                                }
                                NavigationLink(destination: TireWearView()) {
                                    DashboardMenuButton(title: "EQUIPMENT INVENTORY", icon: "shoe.2.fill", color: .orange)
                                }
                            }
                            .padding(.horizontal)
                            
                            // 5. DESTRUCTIVE CONTROLS
                            Button(action: purgeDatabase) {
                                Text("FACTORY RESET: PURGE DATA CACHE")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(ColorTheme.critical.opacity(0.6))
                                    .padding(.vertical, 20)
                            }
                        }
                    }
                }
                .task {
                    await bootSystem()
                }
                .sheet(isPresented: $showingManualOverride) {
                    // Pass existing log and history to the extracted sheet
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
                let planDescriptor = FetchDescriptor<PlannedMission>()
                            let existingMissions = (try? context.fetch(planDescriptor)) ?? []
                            
                            if existingMissions.isEmpty {
                                print("⚠️ No Macro-Cycle found. Ingesting hmPlan.csv...")
                                let parsedMissions = CSVParserEngine.generateMacroCycle()
                                
                                await MainActor.run {
                                    for mission in parsedMissions {
                                        context.insert(mission)
                                    }
                                    try? context.save()
                                    print("✅ MACRO-CYCLE SECURED: \(parsedMissions.count) missions loaded into SwiftData.")
                                }
                            }
                
                // ✨ 1. HISTORICAL BACKFILL ENGINE ✨
                // If database lacks enough data for a trendline, scrape the last 30 days.
                if logs.count < 2 {
                    let historyData = await healthManager.fetchHistoricalBiometrics(daysBack: 30)
                    
                    // Sort chronologically (oldest to newest) to correctly build the Readiness Baseline
                    let sortedData = historyData.sorted { $0.date < $1.date }
                    
                    await MainActor.run {
                        var rollingHistory: [TelemetryLog] = []
                        for bio in sortedData {
                            // Calculate score using the history up to that specific day
                            let score = ReadinessEngine.computeReadiness(
                                todayHRV: bio.hrv,
                                todaySleep: bio.sleepHours,
                                history: rollingHistory
                            )
                            
                            let newLog = TelemetryLog(
                                date: bio.date,
                                hrv: bio.hrv,
                                restingHR: bio.restingHR,
                                sleepDuration: bio.sleepHours,
                                weightKG: 0.0, // Historical weight skipped to save memory
                                readinessScore: score
                            )
                            context.insert(newLog)
                            // Insert at beginning to simulate the @Query descending sort order
                            rollingHistory.insert(newLog, at: 0)
                        }
                        try? context.save()
                    }
                }
                
                // 2. FETCH TODAY'S LIVE DATA
                let metrics = try await healthManager.fetchMorningReadiness()
                let latestWeight = try await healthManager.fetchLatestWeight()
                
                // Force a manual fetch to guarantee we include the newly backfilled data in today's calculation
                let descriptor = FetchDescriptor<TelemetryLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
                let updatedLogs = (try? context.fetch(descriptor)) ?? logs
                
                let calculatedScore = ReadinessEngine.computeReadiness(
                    todayHRV: metrics.hrv,
                    todaySleep: metrics.sleepHours,
                    history: updatedLogs
                )
                
                // 3. PERSIST TODAY'S LOG
                await MainActor.run {
                    if let existingLog = todayLog {
                        if metrics.hrv > 0 { existingLog.hrv = metrics.hrv }
                        if metrics.restingHR > 0 { existingLog.restingHR = metrics.restingHR }
                        if metrics.sleepHours > 0 { existingLog.sleepDuration = metrics.sleepHours }
                        if latestWeight > 0 { existingLog.weightKG = latestWeight }
                        
                        existingLog.readinessScore = ReadinessEngine.computeReadiness(
                            todayHRV: existingLog.hrv,
                            todaySleep: existingLog.sleepDuration,
                            history: updatedLogs
                        )
                    } else {
                        let newLog = TelemetryLog(
                            date: .now,
                            hrv: metrics.hrv,
                            restingHR: metrics.restingHR,
                            sleepDuration: metrics.sleepHours,
                            weightKG: latestWeight,
                            readinessScore: calculatedScore
                        )
                        context.insert(newLog)
                    }
                    try? context.save()
                }
                
                // 4. Background Physiological Scan (Push Notifications)
                alertManager.evaluatePhysiologicalLoad(currentReadiness: calculatedScore)
                
                await MainActor.run { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                
            } catch {
                print("❌ Boot Fault: \(error.localizedDescription)")
            }
        }
    
    // MARK: - ⚠️ LOGIC: SYSTEM OVERRIDE
    private func purgeDatabase() {
        do {
            try context.delete(model: TelemetryLog.self)
            try context.delete(model: ChassisSnapshot.self)
            try context.delete(model: RunningShoe.self)
            try context.delete(model: KineticSession.self)
            try context.save()
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("❌ PURGE FAULT: \(error.localizedDescription)")
        }
    }
}
