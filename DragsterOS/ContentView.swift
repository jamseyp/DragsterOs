import SwiftUI
import CoreData

struct ContentView: View {
    // 1. DATABASE CONNECTIVITY
    @Environment(\.managedObjectContext) private var viewContext
    
    // 2. INPUT STATE (The Sensors)
    @State private var hrvValue: Double = 5.0
    @State private var sleepValue: Double = 5.0
    @State private var sorenessValue: Double = 5.0
    
    // 3. THE ENGINE
    let engine = ReadinessEngine()
    
    // 4. COMPUTED PROPERTY FOR THE GAUGE
    var readinessScore: Double {
        // Since ReadinessEngine returns an Int out of 100, we convert it for the UI
        engine.calculateScore(hrv: hrvValue, sleepHours: sleepValue, rhr: PerformanceConstants.baselineRHR, baselineHRV: PerformanceConstants.baselineHRV)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // THE CANVAS: Pure black background for the dashboard
                Color.black.ignoresSafeArea()
                
                // THE SUSPENSION (Allows scrolling to prevent overlapping)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        // 1️⃣ THE GAUGE DISPLAY
                        VStack {
                            Text("DRAGSTER READINESS")
                                .font(.caption)
                                .tracking(2)
                                .foregroundColor(.gray)
                            
                            // Fixed string interpolation
                            Text(String(format: "%.1f", readinessScore))
                                .font(.system(size: 80, weight: .black, design: .monospaced))
                                .foregroundColor(scoreColor)
                                .shadow(color: scoreColor.opacity(0.4), radius: 15, x: 0, y: 0)
                        }
                        .padding(.top, 20)
                        
                        Divider().background(Color.white.opacity(0.2)).padding(.horizontal)
                        
                        // 2️⃣ THE INPUTS (SLIDERS)
                        VStack(alignment: .leading, spacing: 25) {
                            MetricSlider(label: "HRV (Nervous System)", value: $hrvValue, icon: "bolt.heart.fill")
                            MetricSlider(label: "Sleep (Recovery)", value: $sleepValue, icon: "moon.stars.fill")
                            MetricSlider(label: "Soreness (Chassis)", value: $sorenessValue, icon: "figure.walk")
                        }
                        .padding(.horizontal)
                        
                        // 3️⃣ THE IGNITION BUTTON (SAVE)
                        Button(action: saveEntry) {
                            Label("SAVE TO PADDOCK", systemImage: "square.and.arrow.down.fill")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(white: 0.15)) // Sleek dark button
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 2) // Neon red accent
                                )
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Divider().background(Color.white.opacity(0.2)).padding(.horizontal)
                        
                        // 4️⃣ THE PADDOCK MODULES
                        VStack(spacing: 12) {
                            NavigationLink(destination: PaddockView()) {
                                DashboardMenuButton(title: "LIVE SENSOR TELEMETRY", icon: "waveform.path.ecg", color: .orange)
                            }
                            NavigationLink(destination: TelemetryDashboardView()) {
                                DashboardMenuButton(title: "VIEW MORNING REPORT", icon: "chart.bar.xaxis", color: .cyan)
                            }
                            NavigationLink(destination: GarageLogView()) {
                                DashboardMenuButton(title: "OPEN GARAGE LOG", icon: "list.dash.header.rectangle", color: .purple)
                            }
                            NavigationLink(destination: MissionView()) {
                                DashboardMenuButton(title: "PADDOCK WHITEBOARD", icon: "list.clipboard.fill", color: .green)
                            }
                            NavigationLink(destination: TireWearView()) {
                                DashboardMenuButton(title: "TIRE WEAR INVENTORY", icon: "shoe.2.fill", color: .yellow)
                            }
                            NavigationLink(destination: ChassisView()) {
                                DashboardMenuButton(title: "CHASSIS TUNING (W/kg)", icon: "scalemass.fill", color: .white)
                            }
                            NavigationLink(destination: PitStopView()) {
                                DashboardMenuButton(title: "PIT STOP TIMER", icon: "timer", color: .red)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 5️⃣ FOOTER
                        Text("RACING SUNDAY: BEACON FELL 10K")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(5)
                            .padding(.bottom, 20)
                    }
                }
            }
            // Enforce Dark Mode on the Navigation Bar
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
        }
    }
    
    // COLOR LOGIC
    var scoreColor: Color {
        if readinessScore >= 7.5 { return .cyan } // Peak Performance Color
        if readinessScore >= 5.0 { return .green }
        return .red
    }
    
    // MECHANICAL LOGIC: SAVING TO CORE DATA
    private func saveEntry() {
        let newEntry = LogEntry(context: viewContext)
        newEntry.date = Date()
        newEntry.hrv = hrvValue
        newEntry.sleep = sleepValue
        newEntry.soreness = sorenessValue
        newEntry.score = readinessScore

        do {
            try viewContext.save()
            // 🏎️ THE HAPTIC "CLUNK"
            let impact = UIImpactFeedbackGenerator(style: .rigid)
            impact.impactOccurred()
            print("✅ Telemetry Saved to Paddock.")
        } catch {
            print("❌ Engine Fault: Could not save data.")
        }
    }
}

