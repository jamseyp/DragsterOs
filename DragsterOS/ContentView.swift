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
        Double(engine.calculateScore(hrv: hrvValue, sleepHours: sleepValue, rhr: 50.0, baselineHRV: 60.0)) / 10.0
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

// 🎨 THE CANVAS: REUSABLE COMPONENTS

// Extracted the Menu Button to keep the main view elegant
struct DashboardMenuButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .opacity(0.5)
        }
        .font(.system(size: 14, weight: .bold, design: .monospaced))
        .foregroundColor(color)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MetricSlider: View {
    let label: String
    @Binding var value: Double
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            HStack {
                Slider(value: $value, in: 1...10, step: 0.5)
                    .accentColor(.white)
                
                // Fixed String Interpolation
                Text(String(format: "%.1f", value))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 50)
                    .padding(.vertical, 5)
                    .background(Color(white: 0.15))
                    .cornerRadius(5)
            }
        }
        .padding(.vertical, 5)
    }
}

struct PaddockView: View {
    @StateObject var hkManager = HealthKitManager()
    
    // 1. THE NAVIGATION CONTROLLER
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 30) {
                
                // 2. THE CUSTOM BACK BUTTON
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("DASHBOARD")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.gray)
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // Central Content
                VStack(spacing: 30) {
                    Text("LIVE SENSOR DATA")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 10) {
                        Text("HEART RATE")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text(hkManager.latestHR > 0 ? "\(Int(hkManager.latestHR))" : "--")
                                .font(.system(size: 60, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("BPM")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        }
                        
                        Text("SOURCE: \(hkManager.sensorName)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(white: 0.2))
                            .cornerRadius(5)
                            .foregroundColor(.gray)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(white: 0.2), lineWidth: 1)
                    )
                    
                    Button(action: { hkManager.requestAuthorization() }) {
                        Text("CALIBRATE SENSORS")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
