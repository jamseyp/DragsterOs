import SwiftUI
import SwiftData

// MARK: - 🔋 THERMODYNAMIC WIDGET
struct ThermodynamicFuelWidget: View {
    // Inputs from the Dashboard
    let plannedTier: String?
    let currentWeightKG: Double // Retained for compatibility with ContentView
    
    // State Variables
    @State private var healthManager = HealthKitManager.shared
    @State private var actualProtein: Double = 0
    @State private var actualCarbs: Double = 0
    @State private var actualFat: Double = 0
    @State private var actualIntakeCals: Double = 0
    @State private var isLoading = true
    @State private var showingCalibration = false
    
    // Computed Targets
    private var target: MacroTarget {
        NutritionEngine.getTarget(for: plannedTier)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // HEADER
            HStack {
                Text("THERMODYNAMIC STATE")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                
                Spacer()
                
                // NEW: Calibration Trigger
                                Button(action: { showingCalibration = true }) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 12))
                                        .foregroundStyle(ColorTheme.textMuted)
                                }
                                .padding(.trailing, 4)
                
                Text((plannedTier ?? "LOW").uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ColorTheme.surfaceBorder)
                    .foregroundStyle(ColorTheme.prime)
                    .clipShape(Capsule())
            }
            
            if isLoading {
                ProgressView().tint(ColorTheme.prime).frame(maxWidth: .infinity, minHeight: 80)
            } else {
                // TOTAL CALORIES GAUGE
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(actualIntakeCals))")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text("/ \(Int(target.calories)) KCAL")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                    Text("TARGET DICTATED BY FUEL TIER")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime.opacity(0.7))
                }
                
                // MACRO GRID
                HStack(spacing: 8) {
                    MacroProgressCard(
                        title: "PROTEIN",
                        current: actualProtein,
                        target: target.protein,
                        color: .blue
                    )
                    
                    MacroProgressCard(
                        title: "CARBS",
                        current: actualCarbs,
                        target: target.carbs,
                        color: .orange
                    )
                    
                    MacroProgressCard(
                        title: "FAT",
                        current: actualFat,
                        target: target.fat,
                        color: .purple
                    )
                }
            }
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            // Fetch ONLY intake macros (Ignoring Apple Health BMR/Active Burn)
            let macros = await healthManager.fetchDailyMacros()
            let energy = await healthManager.fetchEnergyBalance()
            
            await MainActor.run {
                self.actualProtein = macros.protein
                self.actualCarbs = macros.carbs
                self.actualFat = macros.fat
                self.actualIntakeCals = energy.intake
                self.isLoading = false
            }
        }
        .sheet(isPresented: $showingCalibration) {
                    FuelTierConfigurationSheet()
                }
    }
}

// MARK: - 🧱 SUB-COMPONENT: MACRO CARD
struct MacroProgressCard: View {
    let title: String
    let current: Double
    let target: Double
    let color: Color
    
    var percentage: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(ColorTheme.background)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 6)
            
            // Values
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(current))")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
                Text("/\(Int(target))g")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
            }
        }
        .padding(12)
        .background(ColorTheme.surfaceBorder.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
