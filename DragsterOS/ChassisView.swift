import SwiftUI

struct ChassisView: View {
    // Current state inputs
    @State private var weight: Double = 95.8
    @State private var maxPower: Double = 336.0
    
    // 1. THE NAVIGATION CONTROLLER
    @Environment(\.dismiss) var dismiss
    
    // The Engine Calculation
    var powerToWeight: Double {
        return maxPower / weight
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
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
            
            VStack(spacing: 30) {
                Text("CHASSIS SPECS")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top)
                
                // THE OUTPUT GAUGE
                VStack(spacing: 10) {
                    Text("POWER-TO-WEIGHT RATIO")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fontWeight(.bold)
                    
                    Text("\(powerToWeight, specifier: "%.2f")")
                        .font(.system(size: 70, weight: .black, design: .monospaced))
                        // Over 3.5 W/kg is elite territory!
                        .foregroundColor(powerToWeight >= 3.5 ? .purple : .cyan)
                    
                    Text("WATTS PER KILOGRAM (W/kg)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.15))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // THE INPUT SLIDERS
                VStack(spacing: 25) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("CHASSIS WEIGHT (KG)")
                                .foregroundColor(.gray).font(.caption).fontWeight(.bold)
                            Spacer()
                            Text("\(weight, specifier: "%.1f") kg").foregroundColor(.white).font(.headline.monospaced())
                        }
                        Slider(value: $weight, in: 85...105, step: 0.1)
                            .accentColor(.white)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("MAX AEROBIC POWER (WATTS)")
                                .foregroundColor(.gray).font(.caption).fontWeight(.bold)
                            Spacer()
                            Text("\(maxPower, specifier: "%.0f") W").foregroundColor(.yellow).font(.headline.monospaced())
                        }
                        Slider(value: $maxPower, in: 250...400, step: 1.0)
                            .accentColor(.yellow)
                    }
                }
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Tuning")
        .navigationBarTitleDisplayMode(.inline)
    }
}
