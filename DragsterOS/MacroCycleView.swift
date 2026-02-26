import SwiftUI
import SwiftData

// MARK: - 🗓️ MACRO-CYCLE COMMAND
struct MacroCycleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // Fetch upcoming missions, sorted chronologically
    @Query(sort: \OperationalDirective.date, order: .forward) private var missions: [OperationalDirective]
    
    // State for CRUD Operations
    @State private var editingMission: OperationalDirective?
    @State private var showingAddSheet = false
    
    // Filter out past missions for the active view (optional tactical choice)
    private var upcomingMissions: [OperationalDirective] {
        let today = Calendar.current.startOfDay(for: .now)
        return missions.filter { $0.date >= today }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // SYSTEM HEADER
            HStack {
                Text("Planned Workouts")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                Spacer()
                Text("\(upcomingMissions.count) PENDING")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.prime)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            
            
            if upcomingMissions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(ColorTheme.surfaceBorder)
                    Text("NO MISSIONS SCHEDULED")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // THE DATA LIST (Supports Swipe-to-Delete)
                List {
                    ForEach(upcomingMissions) { mission in
                        DirectiveRowCard(directive: mission)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                editingMission = mission // Triggers the Edit Sheet
                            }
                    }
                    .onDelete(perform: deleteMission)
                }
                .listStyle(.plain)
            }
            
            // MANUAL INJECTION BUTTON
            Button(action: { showingAddSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Planned Workout")
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
        .applyTacticalOS(title: "Training Plan", showBack: true)
        .sheet(item: $editingMission) { mission in
            EditMissionSheet(mission: mission)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddPlannedActivitySheet()
        }
    }
    
    // MARK: - ⚙️ LOGIC: PURGE RECORD
    private func deleteMission(offsets: IndexSet) {
        for index in offsets {
            let missionToDelete = upcomingMissions[index]
            context.delete(missionToDelete)
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
struct EditMissionSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // ✨ @Bindable directly mutates the database object in real-time
    @Bindable var mission: OperationalDirective
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Workout Details")) {
                    // ✨ FIXED: Bound to 'activity' instead of 'title' to match your model
                    TextField("Activity", text: $mission.activity)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    
                    DatePicker("Date & Time", selection: $mission.date, displayedComponents: [.date])
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                
                // Assuming you removed targetLoad from your model entirely. If it exists, uncomment this.
                /*
                Section(header: Text("PHYSIOLOGICAL TARGETS")) {
                    HStack {
                        Text("TARGET LOAD (TSS)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        Spacer()
                        TextField("0", value: $mission.targetLoad, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(ColorTheme.prime)
                    }
                }
                */
                
                Section(header: Text("Fueling")) {
                    Picker("Fuel Tier", selection: $mission.fuelTier) {
                        Text("Low").tag("LOW")
                        Text("Medium").tag("MED")
                        Text("High").tag("HIGH")
                        Text("Race").tag("RACE")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tint(ColorTheme.prime)
                }
            }
            .applyTacticalOS(title: "Edit Workout", showBack: false)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
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

// MARK: - 🧱 SUB-COMPONENT: DIRECTIVE ROW UI
struct DirectiveRowCard: View {
    let directive: OperationalDirective
    
    // Determine color based on fuel tier
    private var tierColor: Color {
        let tier = directive.fuelTier.uppercased()
        if tier.contains("HIGH") || tier.contains("RACE") { return ColorTheme.critical }
        if tier.contains("MED") { return .yellow }
        return .green
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(directive.date.formatted(date: .abbreviated, time: .omitted).uppercased())
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                    
                    Text(directive.activity.uppercased())
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                Text(directive.fuelTier.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6).padding(.vertical, 4)
                    .background(tierColor.opacity(0.2))
                    .foregroundStyle(tierColor)
                    .clipShape(Capsule())
            }
            
            // If you want to display duration or another metric, you can add it here.
            /*
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(directive.targetLoad))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorTheme.prime)
                Text(" TARGET TSS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
            }
            */
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
