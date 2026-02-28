import SwiftUI
import SwiftData

struct RegistrySettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @Query private var registries: [UserRegistry]
    
    var body: some View {
        NavigationStack {
            Group {
                if let registry = registries.first {
                    Form {
                        // 1. CORE BIOMETRICS
                        Section(header: Text("Core Biometrics")) {
                            HStack {
                                Text("Target Weight (kg)")
                                Spacer()
                                TextField("75.0", value: Bindable(registry).targetWeight, format: .number)
                                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).foregroundStyle(ColorTheme.prime)
                            }
                            HStack {
                                Text("Resting HR (bpm)")
                                Spacer()
                                TextField("50", value: Bindable(registry).restingHR, format: .number)
                                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundStyle(ColorTheme.prime)
                            }
                            HStack {
                                Text("Maximum HR (bpm)")
                                Spacer()
                                TextField("190", value: Bindable(registry).maxHR, format: .number)
                                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundStyle(ColorTheme.critical)
                            }
                            HStack {
                                Text("VO2 Max (ml/kg/min)")
                                Spacer()
                                TextField("50.0", value: Bindable(registry).vo2Max, format: .number)
                                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).foregroundStyle(ColorTheme.prime)
                            }
                        }
                        
                        // 2. AUTONOMIC ZONES
                        Section(header: Text("Heart Rate Zones"), footer: Text("Set the absolute ceiling for each zone.")) {
                            HStack {
                                Text("Zone 1 (Recovery)")
                                Spacer()
                                TextField("130", value: Bindable(registry).zone1Max, format: .number)
                                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundStyle(ColorTheme.textPrimary)
                            }
                            HStack {
                                Text("Zone 2 (Aerobic)")
                                Spacer()
                                TextField("145", value: Bindable(registry).zone2Max, format: .number)
                                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundStyle(ColorTheme.prime)
                            }
                            HStack {
                                Text("Zone 3 (Tempo)")
                                Spacer()
                                TextField("160", value: Bindable(registry).zone3Max, format: .number)
                                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundStyle(.yellow)
                            }
                            HStack {
                                Text("Zone 4 (Threshold)")
                                Spacer()
                                TextField("175", value: Bindable(registry).zone4Max, format: .number)
                                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundStyle(.orange)
                            }
                        }
                        
                        // 3. KINETIC OUTPUT
                        Section(header: Text("Performance Ceiling")) {
                            HStack {
                                Text("Bike FTP (Watts)")
                                Spacer()
                                TextField("250", value: Bindable(registry).functionalThresholdPower, format: .number)
                                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundStyle(ColorTheme.prime)
                            }
                            HStack {
                                Text("Race Pace (sec/km)")
                                Spacer()
                                TextField("300", value: Bindable(registry).targetRacePaceSeconds, format: .number)
                                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundStyle(ColorTheme.prime)
                            }
                        }
                        
                        // 4. THERMODYNAMICS
                        Section(header: Text("Fueling Bases")) {
                            Toggle("Override TDEE Calculation", isOn: Bindable(registry).isTDEEOverridden)
                                .tint(ColorTheme.prime)
                            
                            HStack {
                                Text(registry.isTDEEOverridden ? "Manual TDEE (kcal)" : "Calculated TDEE (kcal)")
                                Spacer()
                                if registry.isTDEEOverridden {
                                    TextField("2600", value: Bindable(registry).manualTDEE, format: .number)
                                        .keyboardType(.numberPad).multilineTextAlignment(.trailing).foregroundStyle(ColorTheme.prime)
                                } else {
                                    Text("\(registry.effectiveTDEE)")
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(ColorTheme.textMuted)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(ColorTheme.background.ignoresSafeArea())
                    
                } else {
                    VStack(spacing: 16) {
                        ProgressView().tint(ColorTheme.prime)
                        Text("Initializing Registry...")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ColorTheme.background.ignoresSafeArea())
                }
            }
            .applyTacticalOS(title: "System Calibration", showBack: false)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Commit") {
                        try? context.save()
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        dismiss()
                    }
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.prime)
                }
            }
            .onAppear { initializeRegistryIfNeeded() }
        }
    }
    
    private func initializeRegistryIfNeeded() {
        if registries.isEmpty {
            let newRegistry = UserRegistry()
            context.insert(newRegistry)
            try? context.save()
        }
    }
}
