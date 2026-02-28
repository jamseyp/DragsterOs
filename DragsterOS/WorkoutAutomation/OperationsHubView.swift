import SwiftUI
import SwiftData

// MARK: - 🎛️ MAIN HUB (READ & DELETE)
struct OperationsHubView: View {
    @Environment(\.modelContext) private var context
    
    @Query(
        filter: #Predicate<OperationalDirective> { $0.isCompleted == false },
        sort: \OperationalDirective.assignedDate,
        order: .forward
    ) private var upcomingMissions: [OperationalDirective]
    
    @State private var isShowingIngestion = false
    @State private var isShowingManualEntry = false
    @State private var missionToEdit: OperationalDirective? // ✨ Tracks the active edit state
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                if upcomingMissions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 48))
                            .foregroundStyle(ColorTheme.textMuted)
                        Text("No Active Directives")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textPrimary)
                        Text("Awaiting input via JSON or Manual Override.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(upcomingMissions) { mission in
                                MissionCard(directive: mission)
                                    // ✨ THE DELETE & EDIT MENU (Long Press)
                                    .contextMenu {
                                        Button {
                                            missionToEdit = mission
                                        } label: {
                                            Label("Edit Parameters", systemImage: "slider.horizontal.3")
                                        }
                                        
                                        Button(role: .destructive) {
                                            abortMission(mission)
                                        } label: {
                                            Label("Abort Mission", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Operations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { isShowingIngestion = true }) {
                            Label("Ingest JSON Payload", systemImage: "square.and.arrow.down.fill")
                        }
                        Button(action: { isShowingManualEntry = true }) {
                            Label("Manual Override", systemImage: "pencil.and.list.clipboard")
                        }
                    } label: {
                        Image(systemName: "plus.viewfinder")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(ColorTheme.prime)
                    }
                }
            }
            // Create Sheets
            .sheet(isPresented: $isShowingIngestion) {
                IngestionTerminalView()
                    .presentationDetents([.fraction(0.85)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingManualEntry) {
                ManualMissionBuilderView()
            }
            // Update Sheet
            .sheet(item: $missionToEdit) { mission in
                ManualMissionBuilderView(directiveToEdit: mission)
            }
        }
    }
    
    // ✨ THE DELETE EXECUTION
    private func abortMission(_ mission: OperationalDirective) {
        context.delete(mission)
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - 🪪 SUBVIEW: MISSION CARD
struct MissionCard: View {
    let directive: OperationalDirective
    
    private var cleanFuelTier: String {
        directive.fuelTier.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
    
    private var fuelColor: Color {
        switch cleanFuelTier {
        case "LOW": return .green
        case "MED": return .yellow
        case "HIGH": return .orange
        case "RACE": return ColorTheme.critical
        default: return .gray
        }
    }
    
    private var macroStrategy: MacroTarget {
        NutritionEngine.getTarget(for: cleanFuelTier)
    }

    private var isRestDay: Bool {
        directive.discipline.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "REST"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(directive.assignedDate.formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.prime)
                
                Spacer()
                
                Label(cleanFuelTier, systemImage: "fuelpump.fill")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(fuelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(fuelColor.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            HStack {
                Text(directive.missionTitle)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.textPrimary)
                
                Spacer()
                
                Image(systemName: disciplineIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.prime)
            }
            
            if !isRestDay {
                HStack(spacing: 20) {
                    MetricPill(title: "INTERVALS", value: "\(directive.intervalSets)x\(directive.workDurationMinutes)m")
                    MetricPill(title: "TARGET", value: directive.discipline.uppercased() == "STRENGTH" ? "N/A" : "\(directive.workTargetWatts)W")
                    MetricPill(title: "LOAD", value: "\(directive.targetLoad) TSS")
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("FUEL STRATEGY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(fuelColor)
                
                HStack {
                    MacroMiniBadge(label: "P", value: Int(macroStrategy.protein), color: .blue)
                    MacroMiniBadge(label: "C", value: Int(macroStrategy.carbs), color: .green)
                    MacroMiniBadge(label: "F", value: Int(macroStrategy.fat), color: .orange)
                    Spacer()
                    Text("\(Int(macroStrategy.calories)) KCAL")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
            }
            .padding(10)
            .background(fuelColor.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("COACH NOTES")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.prime)
                Text(directive.coachNotes)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
            }
            
            if !isRestDay {
                Button(action: {
                    Task {
                        try? await DirectiveScheduler.shared.pushMissionToWatch(directive: directive)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }) {
                    HStack {
                        Image(systemName: "applewatch.radiowaves.left.and.right")
                        Text("TRANSMIT TO WATCH")
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(ColorTheme.prime)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(isRestDay ? Color.gray.opacity(0.05) : ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isRestDay ? Color.gray.opacity(0.2) : ColorTheme.prime.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var disciplineIcon: String {
        switch directive.discipline.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "RUN": return "figure.run"
        case "SPIN": return "bicycle"
        case "STRENGTH": return "figure.strengthtraining.traditional"
        case "REST": return "bed.double.fill"
        default: return "questionmark.circle"
        }
    }
}

struct MacroMiniBadge: View {
    let label: String
    let value: Int
    let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(color)
            Text("\(value)g").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ColorTheme.textPrimary)
        }
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
            Text(value).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(ColorTheme.prime)
        }
    }
}

// MARK: - 🛠️ SMART BUILDER (CREATE & UPDATE)
struct ManualMissionBuilderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // ✨ If this is populated, the form is in UPDATE mode.
    var directiveToEdit: OperationalDirective?
    
    @State private var assignedDate = Date()
    @State private var discipline = "RUN"
    @State private var fuelTier = "MED"
    @State private var missionTitle = ""
    @State private var targetLoad: Int = 50
    
    @State private var warmupMinutes: Int = 10
    @State private var intervalSets: Int = 1
    @State private var workDurationMinutes: Int = 30
    @State private var workTargetWatts: Int = 200
    @State private var recoveryDurationMinutes: Int = 0
    @State private var cooldownMinutes: Int = 5
    
    @State private var coachNotes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile").font(.caption.monospaced())) {
                    Picker("Discipline", selection: $discipline) {
                        Text("Run").tag("RUN")
                        Text("Spin").tag("SPIN")
                        Text("Strength").tag("STRENGTH")
                        Text("Rest").tag("REST")
                    }
                    Picker("Fuel Tier", selection: $fuelTier) {
                        Text("Low").tag("LOW")
                        Text("Medium").tag("MED")
                        Text("High").tag("HIGH")
                        Text("Race").tag("RACE")
                    }
                    DatePicker("Execution Date", selection: $assignedDate, displayedComponents: .date)
                    TextField("Mission Title", text: $missionTitle)
                    Stepper("Predicted Load: \(targetLoad) TSS", value: $targetLoad, in: 0...300)
                }
                
                if discipline != "REST" {
                    Section(header: Text("Kinetic Parameters").font(.caption.monospaced())) {
                        Stepper("Warmup: \(warmupMinutes) min", value: $warmupMinutes, in: 0...60)
                        Stepper("Sets: \(intervalSets)x", value: $intervalSets, in: 1...20)
                        Stepper("Work Duration: \(workDurationMinutes) min", value: $workDurationMinutes, in: 1...120)
                        
                        if discipline != "STRENGTH" {
                            Stepper("Target Power: \(workTargetWatts) W", value: $workTargetWatts, step: 5)
                            Stepper("Recovery Duration: \(recoveryDurationMinutes) min", value: $recoveryDurationMinutes, in: 0...60)
                        }
                        
                        Stepper("Cooldown: \(cooldownMinutes) min", value: $cooldownMinutes, in: 0...60)
                    }
                }
                
                Section(header: Text("Tactical Briefing").font(.caption.monospaced())) {
                    TextField("Coach Notes...", text: $coachNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: saveDirective) {
                        HStack {
                            Spacer()
                            Text(directiveToEdit == nil ? "AUTHORIZE MISSION" : "UPDATE PARAMETERS")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                            Spacer()
                        }
                    }
                    .disabled(missionTitle.isEmpty)
                }
            }
            .navigationTitle(directiveToEdit == nil ? "Manual Override" : "Edit Mission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abort") { dismiss() }
                }
            }
            .onAppear {
                // ✨ LOAD EXISTING DATA FOR UPDATE
                if let editMode = directiveToEdit {
                    assignedDate = editMode.assignedDate
                    discipline = editMode.discipline
                    fuelTier = editMode.fuelTier
                    missionTitle = editMode.missionTitle
                    targetLoad = editMode.targetLoad
                    warmupMinutes = editMode.warmupMinutes
                    intervalSets = editMode.intervalSets
                    workDurationMinutes = editMode.workDurationMinutes
                    workTargetWatts = editMode.workTargetWatts
                    recoveryDurationMinutes = editMode.recoveryDurationMinutes
                    cooldownMinutes = editMode.cooldownMinutes
                    coachNotes = editMode.coachNotes
                }
            }
        }
    }
    
    // ✨ THE CREATE & UPDATE EXECUTION
    private func saveDirective() {
        if let editMode = directiveToEdit {
            // Update Existing
            editMode.assignedDate = assignedDate
            editMode.discipline = discipline
            editMode.fuelTier = fuelTier
            editMode.missionTitle = missionTitle
            editMode.targetLoad = targetLoad
            editMode.warmupMinutes = discipline == "REST" ? 0 : warmupMinutes
            editMode.intervalSets = discipline == "REST" ? 0 : intervalSets
            editMode.workDurationMinutes = discipline == "REST" ? 0 : workDurationMinutes
            editMode.workTargetWatts = discipline == "REST" || discipline == "STRENGTH" ? 0 : workTargetWatts
            editMode.recoveryDurationMinutes = discipline == "REST" ? 0 : recoveryDurationMinutes
            editMode.cooldownMinutes = discipline == "REST" ? 0 : cooldownMinutes
            editMode.coachNotes = coachNotes
        } else {
            // Create New
            let newMission = OperationalDirective(
                assignedDate: assignedDate,
                discipline: discipline,
                missionTitle: missionTitle,
                missionNotes: "Manual Entry",
                warmupMinutes: discipline == "REST" ? 0 : warmupMinutes,
                intervalSets: discipline == "REST" ? 0 : intervalSets,
                workDurationMinutes: discipline == "REST" ? 0 : workDurationMinutes,
                workTargetWatts: discipline == "REST" || discipline == "STRENGTH" ? 0 : workTargetWatts,
                recoveryDurationMinutes: discipline == "REST" ? 0 : recoveryDurationMinutes,
                cooldownMinutes: discipline == "REST" ? 0 : cooldownMinutes,
                fuelTier: fuelTier,
                targetLoad: targetLoad,
                coachNotes: coachNotes
            )
            context.insert(newMission)
        }
        
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
