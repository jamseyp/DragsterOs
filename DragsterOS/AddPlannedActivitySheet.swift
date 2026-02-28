import SwiftUI
import SwiftData

struct AddPlannedActivitySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 🕹️ LOCAL STATE
    @State private var date = Date()
    @State private var title = ""
    @State private var plannedTSS: Double = 0.0 // ✨ Added numeric TSS
    @State private var fuel = "MED" // Cleaned to match your OperationalDirective structure
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MISSION DETAILS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MISSION PARAMETERS")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.prime)
                            
                            TextField("Activity Title (e.g., Z2 Endurance)", text: $title)
                                .padding()
                                .background(ColorTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(ColorTheme.textPrimary)
                            
                            // ✨ Numeric input for TSS
                            HStack {
                                Text("TARGET TSS")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textMuted)
                                Spacer()
                                TextField("0", value: $plannedTSS, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundStyle(ColorTheme.prime)
                            }
                            .padding()
                            .background(ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            DatePicker("Target Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .padding()
                                .background(ColorTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(ColorTheme.textPrimary)
                        }
                        
                        // NUTRITION & LOGISTICS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("LOGISTICS")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.prime)
                            
                            Picker("Fuel Tier", selection: $fuel) {
                                Text("Low Carb").tag("LOW")
                                Text("Medium Carb").tag("MED")
                                Text("High Carb").tag("HIGH")
                                Text("Race Fuel").tag("RACE")
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .tint(ColorTheme.textPrimary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("FREELANCE PROTOCOL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ABORT") { dismiss() }
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.critical)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("AUTHORIZE") {
                        saveMission()
                    }
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(title.isEmpty ? .gray : ColorTheme.prime)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    // MARK: - ⚙️ LOGIC
    private func saveMission() {
        // ✨ FIXED: Saves to OperationalDirective, not PlannedMission
        let newDirective = OperationalDirective()
        // adjust for new dataset.
        
        context.insert(newDirective)
        
        do {
            try context.save()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            dismiss()
        } catch {
            print("❌ PERSISTENCE FAULT: \(error.localizedDescription)")
        }
    }
}
