import SwiftUI
import SwiftData

// MARK: - 🎛️ OPERATIONS HUB (The Main Weekly Dashboard)
struct OperationsHubView: View {
    @Environment(\.modelContext) private var context
    
    // 1. FETCH ALL ACTIVE MISSIONS
    @Query(
        filter: #Predicate<OperationalDirective> { $0.isCompleted == false },
        sort: \OperationalDirective.assignedDate,
        order: .forward
    ) private var allMissions: [OperationalDirective]
    
    // 2. STATE MANAGEMENT
    @State private var isShowingIngestion = false
    @State private var isShowingManualEntry = false
    @State private var missionToEdit: OperationalDirective? // Triggers the Edit Sheet
    @State private var selectedWeekStart: Date = Date().startOfWeek
    
    // 3. LOGIC: GROUP BY WEEK
    private var weeklyGroups: [WeekGroup] {
        let grouped = Dictionary(grouping: allMissions) { $0.assignedDate.startOfWeek }
        return grouped.map { WeekGroup(startDate: $0.key, missions: $0.value) }
            .sorted { $0.startDate < $1.startDate }
    }
    
    // Get missions for the currently selected week tab
    private var currentWeekMissions: [OperationalDirective] {
        weeklyGroups.first(where: { $0.startDate == selectedWeekStart })?
            .missions.sorted { $0.assignedDate < $1.assignedDate } ?? []
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // --- HEADER & GLOBAL ACTIONS ---
                    HStack {
                        Text("ACTIVE QUEUE: \(allMissions.count)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        Spacer()
                        
                        // Import Button
                        ActionButton(icon: "square.and.arrow.down.fill", label: "IMPORT") {
                            isShowingIngestion = true
                        }
                        
                        // Add Workout Button
                        ActionButton(icon: "plus", label: "ADD") {
                            isShowingManualEntry = true
                        }
                    }
                    .padding(16)
                    .background(ColorTheme.surface)
                    
                    // --- WEEK NAVIGATOR (TABS) ---
                    if !weeklyGroups.isEmpty {
                        WeekNavigator(currentWeek: $selectedWeekStart, groups: weeklyGroups)
                    }
                    
                    // --- WORKOUT LIST ---
                    if allMissions.isEmpty {
                        EmptyStateView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if currentWeekMissions.isEmpty {
                                    // Handle weeks where no workouts exist (but week exists in timeline)
                                    ContentUnavailableView("Rest Week", systemImage: "bed.double.fill", description: Text("No workouts scheduled for this week."))
                                        .padding(.top, 40)
                                } else {
                                    ForEach(currentWeekMissions) { mission in
                                        MissionCard(
                                            directive: mission,
                                            onEdit: { triggerEdit(for: mission) },
                                            onDelete: { deleteMission(mission) }
                                        )
                                        // Swipe Actions (Alternative to Menu)
                                        .swipeActions(edge: .leading) {
                                            Button("Edit") { triggerEdit(for: mission) }.tint(.blue)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button("Delete", role: .destructive) { deleteMission(mission) }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .padding(.bottom, 80) // Space for bottom safe area
                        }
                    }
                }
            }
            .applyTacticalOS(title: "Command Center", showBack: false)
            
            // --- SHEETS ---
            .sheet(isPresented: $isShowingIngestion) {
                IngestionTerminalView().presentationDetents([.fraction(0.85)])
            }
            .sheet(isPresented: $isShowingManualEntry) {
                ManualMissionBuilderView() // Mode: Create New
            }
            .sheet(item: $missionToEdit) { mission in
                ManualMissionBuilderView(directiveToEdit: mission) // Mode: Edit Existing
            }
        }
        .onAppear {
            scrollToCurrentWeek()
        }
    }
    
    // MARK: - Logic Helpers
    private func scrollToCurrentWeek() {
        let today = Date().startOfWeek
        // Try to find "Today's" week, otherwise find the next upcoming one
        if weeklyGroups.contains(where: { $0.startDate == today }) {
            selectedWeekStart = today
        } else if let future = weeklyGroups.first(where: { $0.startDate > today }) {
            selectedWeekStart = future.startDate
        } else if let last = weeklyGroups.last {
            selectedWeekStart = last.startDate
        }
    }
    
    private func triggerEdit(for mission: OperationalDirective) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        missionToEdit = mission
    }
    
    private func deleteMission(_ mission: OperationalDirective) {
        withAnimation {
            context.delete(mission)
            try? context.save()
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - 🪪 SUBVIEW: MISSION CARD (With Edit Menu)
struct MissionCard: View {
    let directive: OperationalDirective
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    private var cleanFuelTier: String { directive.fuelTier.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
    private var isRestDay: Bool { directive.discipline == "REST" }
    
    private var fuelColor: Color {
        switch cleanFuelTier {
        case "LOW": return .green
        case "MED": return .yellow
        case "HIGH": return .orange
        case "RACE": return ColorTheme.critical
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // HEADER: Date & Menu
            HStack {
                Text(directive.assignedDate.formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.prime)
                
                Spacer()
                
                // ✨ THE EDIT MENU (...)
                Menu {
                    Button(action: onEdit) {
                        Label("Edit Parameters", systemImage: "slider.horizontal.3")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ColorTheme.textMuted)
                        .padding(.leading, 12)
                }
            }
            
            // TITLE ROW
            HStack {
                Text(directive.missionTitle)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: isRestDay ? "bed.double.fill" : (directive.discipline == "RUN" ? "figure.run" : (directive.discipline == "SPIN" ? "bicycle" : "figure.strengthtraining.traditional")))
                    .font(.title3)
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.prime)
            }
            
            // STATS ROW (Hidden if Rest Day)
            if !isRestDay {
                HStack(spacing: 12) {
                    MetricPill(title: "STRUCTURE", value: "\(directive.intervalSets)x\(directive.workDurationMinutes)m")
                    if directive.discipline != "STRENGTH" {
                        MetricPill(title: "TARGET", value: "\(directive.workTargetWatts)W")
                    }
                    MetricPill(title: "FUEL", value: cleanFuelTier)
                }
            }
            
            // NOTES
            VStack(alignment: .leading, spacing: 4) {
                Text("COACH'S NOTES")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                Text(directive.coachNotes.isEmpty ? "No notes provided." : directive.coachNotes)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                    .lineLimit(2)
            }
            
            // WATCH ACTION
            if !isRestDay {
                Button(action: { /* Watch Logic */ }) {
                    HStack {
                        Image(systemName: "applewatch")
                        Text("SEND TO WATCH")
                    }
                    .font(.caption.bold().monospaced())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ColorTheme.prime)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(isRestDay ? Color.gray.opacity(0.1) : ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isRestDay ? Color.clear : ColorTheme.prime.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 🛠️ MANUAL BUILDER (Handles Create AND Update)
struct ManualMissionBuilderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // ✨ If populated, we are editing. If nil, we are creating.
    var directiveToEdit: OperationalDirective?
    
    // Form States
    @State private var assignedDate = Date()
    @State private var discipline = "RUN"
    @State private var title = ""
    @State private var workDuration = 30
    @State private var coachNotes = ""
    @State private var fuelTier = "MED"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Core Parameters") {
                    TextField("Workout Title", text: $title)
                    DatePicker("Date", selection: $assignedDate, displayedComponents: .date)
                    Picker("Discipline", selection: $discipline) {
                        Text("Run").tag("RUN")
                        Text("Spin").tag("SPIN")
                        Text("Row").tag("ROW")
                        Text("Strength").tag("STRENGTH")
                        Text("Rest").tag("REST")
                    }
                }
                
                Section("Structure") {
                    Stepper("Duration: \(workDuration) min", value: $workDuration, in: 0...240, step: 5)
                    Picker("Intensity / Fuel", selection: $fuelTier) {
                        Text("Low (Z2)").tag("LOW")
                        Text("Medium (Z3)").tag("MED")
                        Text("High (Z4/Z5)").tag("HIGH")
                    }
                }
                
                Section("Instructions") {
                    TextField("Coach's Notes...", text: $coachNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(directiveToEdit == nil ? "New Workout" : "Edit Workout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(title.isEmpty) }
            }
            .onAppear { loadDataIfEditing() }
        }
    }
    
    private func loadDataIfEditing() {
        if let edit = directiveToEdit {
            assignedDate = edit.assignedDate
            discipline = edit.discipline
            title = edit.missionTitle
            workDuration = edit.workDurationMinutes
            coachNotes = edit.coachNotes
            fuelTier = edit.fuelTier
        }
    }
    
    private func save() {
        if let edit = directiveToEdit {
            // Update Existing
            edit.assignedDate = assignedDate
            edit.discipline = discipline
            edit.missionTitle = title
            edit.workDurationMinutes = workDuration
            edit.coachNotes = coachNotes
            edit.fuelTier = fuelTier
        } else {
            // Create New
            let newMission = OperationalDirective(
                assignedDate: assignedDate, discipline: discipline, missionTitle: title,
                missionNotes: "Manual", workDurationMinutes: workDuration,
                fuelTier: fuelTier, coachNotes: coachNotes
            )
            context.insert(newMission)
        }
        try? context.save()
        dismiss()
    }
}

// MARK: - 🧱 HELPERS & STRUCTS

struct WeekGroup: Identifiable {
    var id: Date { startDate }
    let startDate: Date
    let missions: [OperationalDirective]
}

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(ColorTheme.background)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ColorTheme.prime)
            .clipShape(Capsule())
        }
    }
}

struct WeekNavigator: View {
    @Binding var currentWeek: Date
    let groups: [WeekGroup]
    
    var body: some View {
        HStack {
            Button(action: { shiftWeek(-1) }) {
                Image(systemName: "chevron.left").padding()
                    .foregroundStyle(ColorTheme.prime)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("WEEK COMMENCING")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                Text(currentWeek.formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textPrimary)
            }
            Spacer()
            Button(action: { shiftWeek(1) }) {
                Image(systemName: "chevron.right").padding()
                    .foregroundStyle(ColorTheme.prime)
            }
        }
        .padding(.vertical, 8)
        .background(ColorTheme.surface.opacity(0.5))
        .overlay(Rectangle().frame(height: 1).foregroundStyle(ColorTheme.surfaceBorder), alignment: .bottom)
    }
    
    private func shiftWeek(_ offset: Int) {
        guard let idx = groups.firstIndex(where: { $0.startDate == currentWeek }) else { return }
        let newIdx = idx + offset
        if groups.indices.contains(newIdx) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation { currentWeek = groups[newIdx].startDate }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundStyle(ColorTheme.textMuted)
            Text("No Directives Found")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textPrimary)
            Text("Generate a plan or add a workout manually.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            Spacer()
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

extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) ?? self
    }
}

