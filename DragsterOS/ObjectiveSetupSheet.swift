import SwiftUI
import SwiftData

struct ObjectiveSetupSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // Defaulting to 10 weeks out for a standard macro-cycle
    @State private var targetDate = Calendar.current.date(byAdding: .day, value: 70, to: .now) ?? .now
    @State private var eventName = ""
    @State private var location = ""
    @State private var targetPace = ""
    @State private var targetPower = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("ENGAGEMENT PARAMETERS").font(.caption.monospaced())) {
                        TextField("Operation Name (e.g. LONDON HALF)", text: $eventName)
                            .foregroundStyle(ColorTheme.textPrimary)
                        TextField("Location / AO", text: $location)
                            .foregroundStyle(ColorTheme.textPrimary)
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                            .tint(ColorTheme.prime)
                    }
                    .listRowBackground(ColorTheme.surface)
                    
                    Section(header: Text("SUCCESS CRITERIA").font(.caption.monospaced())) {
                        TextField("Target Pace (e.g. 4:30/km)", text: $targetPace)
                            .foregroundStyle(ColorTheme.textPrimary)
                        TextField("Target Power (e.g. 280W)", text: $targetPower)
                            .foregroundStyle(ColorTheme.textPrimary)
                    }
                    .listRowBackground(ColorTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("SET PRIMARY OBJECTIVE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ABORT") { dismiss() }
                        .foregroundStyle(ColorTheme.textMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("LOCK IN") {
                        saveObjective()
                    }
                    .font(.caption.monospaced().bold())
                    .foregroundStyle(eventName.isEmpty ? .gray : ColorTheme.prime)
                    .disabled(eventName.isEmpty)
                }
            }
        }
    }
    
    private func saveObjective() {
        // Clear old objectives so we only ever have ONE primary focus
        try? context.delete(model: StrategicObjective.self)
        
        let newObjective = StrategicObjective(
            eventName: eventName.uppercased(),
            targetDate: targetDate,
            targetPower: Int(targetPower.replacingOccurrences(of: "W", with: "")) ?? 0,
            targetPace: targetPace,
            location: location.uppercased()
        )
        
        context.insert(newObjective)
        try? context.save()
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        dismiss()
    }
}
