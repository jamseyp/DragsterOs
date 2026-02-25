import SwiftUI
import SwiftData

// 📐 ARCHITECTURE: The Ultimate Command Center.
// Automates data ingestion, processes background alerts, and routes to all subsystems.

struct ContentView: View {
    // 1. SWIFTDATA & SENSORS
    @Environment(\.modelContext) private var context
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    @State private var healthManager = HealthKitManager.shared
    @State private var alertManager = SystemAlertManager.shared
    @State private var isSyncing: Bool = true
    
    var currentReadiness: Double {
        logs.first?.readinessScore ?? 0.0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // 1️⃣ PRIME METRIC: SYSTEM READINESS
                        VStack {
                            Text("SYSTEM READINESS")
                                .font(.caption.monospaced().bold())
                                .tracking(2)
                                .foregroundStyle(ColorTheme.textMuted)
                            
                            ReadinessGauge(score: currentReadiness)
                            
                            if isSyncing {
                                Text("SYNCING BIOMETRICS...")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(ColorTheme.prime)
                                    .opacity(0.8)
                                    .animation(.easeInOut(duration: 1.0).repeatForever(), value: isSyncing)
                            }
                        }
                        .padding(.top, 20)
                        
                        Divider().background(ColorTheme.surfaceBorder).padding(.horizontal)
                        
                        // 2️⃣ THE ROUTING GRID (All Subsystems)
                        VStack(spacing: 12) {
                            // Phase 1: Inputs
                            NavigationLink(destination: MissionView()) {
                                DashboardMenuButton(title: "TACTICAL BRIEFING", icon: "list.clipboard.fill", color: ColorTheme.prime)
                            }
                            NavigationLink(destination: GarageLogView()) {
                                DashboardMenuButton(title: "KINETIC LOGBOOK", icon: "bolt.fill", color: ColorTheme.warning)
                            }
                            
                            // Phase 2: Analytics
                            NavigationLink(destination: ChassisView()) {
                                DashboardMenuButton(title: "MASS & EFFICIENCY (W/kg)", icon: "scalemass.fill", color: ColorTheme.recovery)
                            }
                            NavigationLink(destination: TireWearView()) {
                                DashboardMenuButton(title: "EQUIPMENT INVENTORY", icon: "shoe.2.fill", color: .orange)
                            }
                            
                            // Phase 3: Strategy
                            NavigationLink(destination: PaddockView()) {
                                DashboardMenuButton(title: "PREDICTIVE RACE STRATEGY", icon: "flag.checkered", color: ColorTheme.strategy)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 3️⃣ TARGET LOCK
                        Text("NEXT MILESTONE: BEACON FELL 10K")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.critical)
                            .padding(8)
                            .background(ColorTheme.critical.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .padding(.bottom, 20)
                    }
                    // ⚠️ DEVELOPMENT ONLY: Kill Switch
                                            Button(action: purgeDatabase) {
                                                HStack {
                                                    Image(systemName: "trash.fill")
                                                    Text("FACTORY RESET: PURGE DATA CACHE")
                                                }
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundStyle(ColorTheme.critical)
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(ColorTheme.critical.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                            .padding(.horizontal)
                                            .padding(.bottom, 40)
                }
            }
            .task {
                await bootSystem()
            }
        }
    }
    
    // MARK: - ⚙️ Boot Sequence
    
    private func bootSystem() async {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // 1. Initialize permissions
            await alertManager.requestAuthorization()
            try await healthManager.requestAuthorization()
            
            // 2. Fetch live data
            let metrics = try await healthManager.fetchMorningReadiness()
            let calculatedScore = ReadinessEngine.computeReadiness(
                todayHRV: metrics.hrv,
                todaySleep: metrics.sleepHours,
                history: logs
            )
            
            // 3. Persist to SwiftData
            let startOfDay = Calendar.current.startOfDay(for: .now)
            if let existingLog = logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
                existingLog.hrv = metrics.hrv
                existingLog.restingHR = metrics.restingHR
                existingLog.sleepDuration = metrics.sleepHours
                existingLog.readinessScore = calculatedScore
            } else {
                let newLog = TelemetryLog(
                    date: .now, hrv: metrics.hrv, restingHR: metrics.restingHR,
                    sleepDuration: metrics.sleepHours, readinessScore: calculatedScore
                )
                context.insert(newLog)
            }
            
            // 4. Background Physiological Scan (Triggers Push Notifications if critical)
            alertManager.evaluatePhysiologicalLoad(currentReadiness: calculatedScore)
            
            // Haptic confirmation
            await MainActor.run { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
            
        } catch {
            print("❌ Boot Fault: \(error.localizedDescription)")
        }
    }
    // MARK: - ⚠️ SYSTEM OVERRIDE: Factory Reset
        private func purgeDatabase() {
            do {
                // ✨ THE COMMAND: SwiftData's modern batch-delete protocol
                try context.delete(model: TelemetryLog.self)
                try context.delete(model: ChassisSnapshot.self)
                try context.delete(model: RunningShoe.self)
                
                // Force the SQLite database to commit the empty state immediately
                try context.save()
                
                // Heavy haptic confirmation that the system is wiped
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)
                
                print("✅ SYSTEM PURGED: Database cache completely cleared.")
                
            } catch {
                print("❌ PURGE FAULT: \(error.localizedDescription)")
            }
        }
}
