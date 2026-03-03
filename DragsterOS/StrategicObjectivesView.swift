import SwiftUI
import SwiftData

// MARK: - 🎯 STRATEGIC OBJECTIVES COMMAND
struct StrategicObjectivesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // Fetch objectives and user registry (for engine calibration)
    @Query(sort: \StrategicObjective.targetDate, order: .forward) private var fetchedObjectives: [StrategicObjective]
    @Query private var registries: [UserRegistry]
    
    // 🧠 Tactical Memory Sort: Prioritizes active targets
    private var objectives: [StrategicObjective] {
        fetchedObjectives.sorted {
            if $0.isCompleted == $1.isCompleted {
                return $0.targetDate < $1.targetDate
            }
            return !$0.isCompleted && $1.isCompleted
        }
    }
    
    // STATE FOR CRUD OPERATIONS
    @State private var editingObjective: StrategicObjective?
    @State private var showingAddSheet = false
    
    // ✨ THE ENGINE STATE: Triggers the PlanPreviewCanvas
    @State private var generatedPlan: [OperationalDirective]? = nil
    @State private var selectedObjectiveName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            
            // SYSTEM HEADER
            HStack {
                Text("Strategic Objectives")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                Spacer()
                let activeCount = objectives.filter { !$0.isCompleted }.count
                Text("\(activeCount) Active")
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
                    Text("No Targets Acquired")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(objectives) { objective in
                        ObjectiveRowCard(objective: objective)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            
                            // ✨ THE ENGINE TRIGGER: Swipe right to build the tactical blueprint
                            .swipeActions(edge: .leading) {
                                if !objective.isCompleted {
                                    Button {
                                        generateBlueprint(for: objective)
                                    } label: {
                                        Label("Build Plan", systemImage: "bolt.fill")
                                    }
                                    .tint(ColorTheme.prime)
                                }
                            }
                            
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                editingObjective = objective
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
                    Text("Establish New Target")
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
        .applyTacticalOS(title: "Primary Objectives", showBack: true)
        
        // --- MODAL LAYERS ---
        
        .sheet(item: $editingObjective) { objective in
            EditObjectiveSheet(objective: objective)
        }
        .sheet(isPresented: $showingAddSheet) {
            // ✨ THE BRIDGE: Catch the new objective and fire the engine!
                        ObjectiveSetupSheet { newObjective in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                generateBlueprint(for: newObjective)
                            }
                        }
        }
        
        // ✨ THE PREVIEW LAYER: This shows the user the plan before saving to DB
        .fullScreenCover(item: Binding(
            get: { generatedPlan != nil ? IdentifiableArray(data: generatedPlan!) : nil },
            set: { if $0 == nil { generatedPlan = nil } }
        )) { planWrapper in
            PlanPreviewCanvas(
                generatedPlan: planWrapper.data,
                objectiveName: selectedObjectiveName
            )
        }
    }
    
    // MARK: - ⚙️ ENGINE EXECUTION
    private func generateBlueprint(for objective: StrategicObjective) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Ensure we have a registry to calibrate the math
        guard let registry = registries.first else {
            print("❌ CALIBRATION FAULT: UserRegistry not found.")
            return
        }
        
        // Inside `generateBlueprint(for:)` in StrategicObjectivesView
                let defaultSkeleton: [Int: [BlueprintSlot]] = [
                    0: [.init(category: .easyRun, timeOfDay: .am), .init(category: .strengthUpper, timeOfDay: .pm)],
                    1: [.init(category: .recoverySpin, timeOfDay: .am)],
                    2: [.init(category: .speedRun, timeOfDay: .am)],
                    3: [.init(category: .easyRun, timeOfDay: .am), .init(category: .strengthLower, timeOfDay: .pm)],
                    4: [.init(category: .thresholdRun, timeOfDay: .am)],
                    5: [.init(category: .easyRun, timeOfDay: .am)],
                    6: [.init(category: .longRun, timeOfDay: .am)]
                ]

                let config = TrainingEngineService.PlanConfiguration(
                    objective: objective,
                    registry: registry,
                    currentCTL: 45.0,
                    startDate: Date(),
                    initialWeeklyMinutes: 180.0,
                    skeleton: defaultSkeleton // ✨ Passes your exact 95kg Rebuild Hybrid Split
                )
        
   
        
        do {
            // Run the Hudson/80-20 Math
            let plan = try TrainingEngineService.generatePlan(config: config)
            self.selectedObjectiveName = objective.eventName
            self.generatedPlan = plan // This state change launches the fullScreenCover
        } catch {
            print("❌ ENGINE FAULT: \(error.localizedDescription)")
        }
    }
    
    private func deleteObjective(offsets: IndexSet) {
        for index in offsets {
            let objectiveToDelete = objectives[index]
            context.delete(objectiveToDelete)
        }
        try? context.save()
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}

// ✨ HELPER: Makes the plan array identifiable for the sheet
struct IdentifiableArray<T>: Identifiable {
    let id = UUID()
    let data: [T]
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
                Section(header: Text("Target Parameters")) {
                    TextField("Event Name", text: $objective.eventName)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    
                    TextField("Location", text: $objective.location)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                    
                    DatePicker("Target Date", selection: $objective.targetDate, displayedComponents: [.date])
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                
                Section(header: Text("Kinetic Targets")) {
                    HStack {
                        Text("Target Power (W)")
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
                        Text("Target Pace")
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
                    Toggle("Mission Accomplished", isOn: $objective.isCompleted)
                        .tint(.green)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                } footer: {
                    Text("Marking this as accomplished will archive it and remove it from active tracking.")
                        .font(.system(size: 10))
                }
            }
            .applyTacticalOS(title: "Recalibrate Target", showBack: false)
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
                    Text("T-Minus \(max(daysRemaining, 0)) Days • \(objective.location)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(objective.isCompleted ? ColorTheme.textMuted : ColorTheme.warning)
                    
                    Text(objective.eventName)
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
                    Text(objective.targetDate.formatted(date: .abbreviated, time: .omitted))
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
                    Text(objective.targetPace)
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
