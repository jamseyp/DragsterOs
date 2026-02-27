import SwiftUI
import SwiftData


// MARK: - 🎯 STRATEGIC OBJECTIVES COMMAND
struct StrategicObjectivesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // Fetch objectives from SwiftData, sorting purely by date
        @Query(sort: \StrategicObjective.targetDate, order: .forward) private var fetchedObjectives: [StrategicObjective]
        
        // 🧠 Tactical Memory Sort: Prioritizes active targets, then chronologically
        private var objectives: [StrategicObjective] {
            fetchedObjectives.sorted {
                if $0.isCompleted == $1.isCompleted {
                    return $0.targetDate < $1.targetDate
                }
                return !$0.isCompleted && $1.isCompleted // Places active (false) above completed (true)
            }
        }
    
    // State for CRUD Operations
    @State private var editingObjective: StrategicObjective?
    @State private var showingAddSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // SYSTEM HEADER
            HStack {
                Text("STRATEGIC OBJECTIVES")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                Spacer()
                let activeCount = objectives.filter { !$0.isCompleted }.count
                Text("\(activeCount) ACTIVE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.prime)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            if objectives.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "scope")
                        .font(.system(size: 40))
                        .foregroundStyle(ColorTheme.surfaceBorder)
                    Text("NO TARGETS ACQUIRED")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // THE DATA LIST (Supports Swipe-to-Delete)
                List {
                    ForEach(objectives) { objective in
                        ObjectiveRowCard(objective: objective)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                editingObjective = objective // Triggers the Edit Sheet
                            }
                    }
                    .onDelete(perform: deleteObjective)
                }
                .listStyle(.plain)
            }
            
            // MANUAL INJECTION BUTTON
            Button(action: { showingAddSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("ESTABLISH NEW TARGET")
                }
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.prime)
                .foregroundStyle(ColorTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
            .padding(.top, 12)
        }
        .applyTacticalOS(title: "PRIMARY OBJECTIVES", showBack: true)
        .sheet(item: $editingObjective) { objective in
            EditObjectiveSheet(objective: objective)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingAddSheet) {
            ObjectiveSetupSheet()
                .presentationDetents([.large])
        }
    }
    
    // MARK: - ⚙️ LOGIC: PURGE RECORD
    private func deleteObjective(offsets: IndexSet) {
        for index in offsets {
            let objectiveToDelete = objectives[index]
            context.delete(objectiveToDelete)
        }
        do {
            try context.save()
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } catch {
            print("❌ DELETE FAULT: \(error.localizedDescription)")
        }
    }
}

// MARK: - 🧱 SUB-COMPONENT: EDIT SHEET (@Bindable)
struct EditObjectiveSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // ✨ @Bindable directly mutates the database object
    @Bindable var objective: StrategicObjective
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("TARGET PARAMETERS")) {
                    TextField("Event Name", text: $objective.eventName)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    
                    TextField("Location", text: $objective.location)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                    
                    DatePicker("Target Date", selection: $objective.targetDate, displayedComponents: [.date])
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                
                Section(header: Text("KINETIC TARGETS")) {
                    HStack {
                        Text("TARGET POWER (W)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        Spacer()
                        TextField("0", value: $objective.targetPower, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(ColorTheme.prime)
                    }
                    
                    HStack {
                        Text("TARGET PACE")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        Spacer()
                        TextField("4:30 /km", text: $objective.targetPace)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(ColorTheme.prime)
                    }
                }
                
                Section {
                    Toggle("MISSION ACCOMPLISHED", isOn: $objective.isCompleted)
                        .tint(.green)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                } footer: {
                    Text("Marking this as accomplished will archive it and remove it from active tracking.")
                        .font(.system(size: 10))
                }
            }
            .applyTacticalOS(title: "RECALIBRATE TARGET", showBack: false)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("COMMIT") {
                        try? context.save()
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        dismiss()
                    }
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.prime)
                }
            }
        }
    }
}

// MARK: - 🧱 SUB-COMPONENT: OBJECTIVE ROW UI
struct ObjectiveRowCard: View {
    let objective: StrategicObjective
    
    // Calculate days remaining
    private var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: objective.targetDate))
        return components.day ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("T-MINUS \(max(daysRemaining, 0)) DAYS • \(objective.location.uppercased())")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(objective.isCompleted ? ColorTheme.textMuted : ColorTheme.warning)
                    
                    Text(objective.eventName.uppercased())
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundStyle(objective.isCompleted ? ColorTheme.textMuted : ColorTheme.textPrimary)
                        .strikethrough(objective.isCompleted, color: ColorTheme.textMuted)
                }
                
                Spacer()
                
                if objective.isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                } else {
                    Text(objective.targetDate.formatted(date: .abbreviated, time: .omitted).uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6).padding(.vertical, 4)
                        .background(ColorTheme.surfaceBorder)
                        .foregroundStyle(ColorTheme.textMuted)
                        .clipShape(Capsule())
                }
            }
            
            // KINETIC METRICS
            HStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(objective.targetPower)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.prime)
                    Text(" W")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(objective.targetPace.uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.prime)
                }
            }
            .opacity(objective.isCompleted ? 0.5 : 1.0)
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(objective.isCompleted ? Color.green.opacity(0.3) : ColorTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
