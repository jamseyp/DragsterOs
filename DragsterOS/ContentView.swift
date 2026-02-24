
import SwiftUI
import CoreData

struct ContentView: View {
    // 1. DATABASE CONNECTIVITY
    @Environment(\.managedObjectContext) private var viewContext
    
    // 2. INPUT STATE (The Sensors)
    @State private var hrvValue: Double = 5.0
    @State private var sleepValue: Double = 5.0
    @State private var sorenessValue: Double = 5.0
    
    // 3. THE ENGINE (Assuming you have this in another file)
    let engine = ReadinessEngine()
    
    // 4. COMPUTED PROPERTY FOR THE GAUGE
    var readinessScore: Double {
        engine.calculateScore(hrv: hrvValue, sleep: sleepValue, soreness: sorenessValue)
    }
    
    var body: some View {
            NavigationView {
                // THE SUSPENSION (Allows scrolling to prevent overlapping)
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // THE GAUGE DISPLAY
                        VStack {
                            Text("DRAGSTER READINESS")
                                .font(.caption)
                                .tracking(2)
                                .foregroundColor(.gray)
                            
                            Text("\(readinessScore, specifier: "%.1f")")
                                .font(.system(size: 80, weight: .black, design: .monospaced))
                                .foregroundColor(scoreColor)
                        }
                        .padding(.top, 40)
                        
                        Divider()
                        
                        // THE INPUTS (SLIDERS)
                        VStack(alignment: .leading, spacing: 25) {
                            MetricSlider(label: "HRV (Nervous System)", value: $hrvValue, icon: "bolt.heart.fill")
                            MetricSlider(label: "Sleep (Recovery)", value: $sleepValue, icon: "moon.stars.fill")
                            MetricSlider(label: "Soreness (Chassis)", value: $sorenessValue, icon: "figure.walk")
                        }
                        .padding(.horizontal)
                        
                        // THE IGNITION BUTTON (SAVE)
                        Button(action: saveEntry) {
                            Label("SAVE TO PADDOCK", systemImage: "square.and.arrow.down.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // 🚀 NEW: TELEMETRY NAVIGATION LINK
                        NavigationLink(destination: PaddockView()) {
                            Label("LIVE SENSOR TELEMETRY", systemImage: "waveform.path.ecg")
                                .font(.headline)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // FOOTER
                        Text("RACING SUNDAY: BEACON FELL 10K")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(5)
                    }
                    .padding(.bottom, 40)
                }
                .navigationTitle("Dragster OS")
            }
        }
    
    // COLOR LOGIC
    var scoreColor: Color {
        if readinessScore > 7.5 { return .green }
        if readinessScore > 5.0 { return .orange }
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
            print("✅ Telemetry Saved to Paddock.")
        } catch {
            print("❌ Engine Fault: Could not save data.")
        }
    }
}

// THE REUSABLE COMPONENT (LEAN & CLEAN)
struct MetricSlider: View {
    let label: String
    @Binding var value: Double
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
            
            HStack {
                // The actual slider
                Slider(value: $value, in: 1...10, step: 0.5)
                    .accentColor(.red)
                
                // The numerical readout
                Text("\(value, specifier: "%.1f")")
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 45)
                    .padding(5)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
            }
        }
        .padding(.vertical, 5)
    }
}

// THE LIVE TELEMETRY VIEW
struct PaddockView: View {
    // Note: Capitalized 'HealthKitManager' to match the class name
    @StateObject var hkManager = healthKitManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("LIVE TELEMETRY")
                .font(.system(.largeTitle, design: .monospaced))
                .fontWeight(.bold)
            
            // The Sensor Gauge
            VStack {
                Text("CURRENT HEART RATE")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    // Added a check: if 0, show "--"
                    Text(hkManager.latestHR > 0 ? "\(Int(hkManager.latestHR)) BPM" : "-- BPM")
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                }
                
                // The Source Indicator
                Text("SOURCE: \(hkManager.sensorName)")
                    .font(.system(size: 12, weight: .bold))
                    .padding(5)
                    .background(hkManager.sensorName.contains("Strap") ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(5)
            }
            .padding()
            .background(Color.black.opacity(0.05))
            .cornerRadius(15)
            
            Button("START CALIBRATION") {
                hkManager.requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Paddock")
        .navigationBarTitleDisplayMode(.inline)
    }
}
