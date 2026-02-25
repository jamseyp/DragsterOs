import SwiftUI
import SwiftData

struct AddPlannedActivitySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var date = Date()
    @State private var title = ""
    @State private var intensity = ""
    @State private var fuel = "🟡 MED FUEL TIER (2600 kcal)"
    @State private var notes = ""
    
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
                            
                            TextField("Power Target (e.g., 180W - 200W)", text: $intensity)
                                .padding()
                                .background(ColorTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(ColorTheme.textPrimary)
                            
                            DatePicker("Target Date", selection: $date, displayedComponents: .date)
                                .padding()
                                .background(ColorTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(ColorTheme.textPrimary)
                        }
                        
                        // NUTRITION & NOTES
                        VStack(alignment: .leading, spacing: 16) {
                            Text("LOGISTICS")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.prime)
                            
                            Picker("Fuel Tier", selection: $fuel) {
                                Text("Low Carb").tag("🟢 LOW FUEL TIER (2200 kcal)")
                                Text("Medium Carb").tag("🟡 MED FUEL TIER (2600 kcal)")
                                Text("High Carb").tag("🔴 HIGH FUEL TIER (3000 kcal)")
                                Text("Race Fuel").tag("🏁 RACE FUEL")
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .tint(ColorTheme.textPrimary)
                            
                            TextField("Commander's Intent (Notes)", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(ColorTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(ColorTheme.textPrimary)
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
                        .foregroundStyle(ColorTheme.critical)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("AUTHORIZE") {
                        saveMission()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(title.isEmpty ? .gray : ColorTheme.prime)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveMission() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-dd" // Matches your CSV format perfectly
        let dateString = formatter.string(from: date)
        
        let newMission = PlannedMission(
            week: 0, // Freelance missions don't need a strict week number
            dateString: dateString,
            date: date,
            activity: title,
            powerTarget: intensity,
            strength: "",
            fuelTier: fuel,
            coachNotes: notes.isEmpty ? "User-defined freelance mission." : notes
        )
        
        context.insert(newMission)
        dismiss()
    }
}
