import SwiftUI
import SwiftData

struct ObjectiveSetupSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // ✨ THE BRIDGE: Closure to trigger the engine in the parent
    var onCommit: (StrategicObjective) -> Void
    
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
                    Section(header: Text("ENGAGEMENT PARAMETERS")) {
                        TextField("Operation Name", text: $eventName)
                        TextField("Location", text: $location)
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    }
                    .listRowBackground(ColorTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("LOCK IN") { saveObjective() }.disabled(eventName.isEmpty)
                }
            }
        }
    }
    
    private func saveObjective() {
        let newObj = StrategicObjective(eventName: eventName.uppercased(), targetDate: targetDate, location: location.uppercased())
        context.insert(newObj)
        try? context.save()
        onCommit(newObj) // ✨ Fire the bridge!
        dismiss()
    }
}
