import SwiftUI
import SwiftData
import Charts

// MARK: - 🗓️ MACRO-CYCLE COMMAND
struct MacroCycleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // Fetch upcoming missions, sorted chronologically
    @Query(sort: \OperationalDirective.date, order: .forward) private var missions: [OperationalDirective]
    
    // State for CRUD Operations
    @State private var editingMission: OperationalDirective?
    @State private var showingAddSheet = false
    
    // 🧠 Filter future missions
    private var upcomingMissions: [OperationalDirective] {
        let today = Calendar.current.startOfDay(for: .now)
        return missions.filter { $0.date >= today }
    }
    
    // 🧠 Group missions into logical Micro-Cycles (Weeks)
    private var microCycles: [(weekStart: Date, missions: [OperationalDirective], totalLoad: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: upcomingMissions) { mission -> Date in
            // Snap the date to the Monday of that specific week
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: mission.date)
            return calendar.date(from: components) ?? mission.date
        }
        
        return grouped.map { key, value in
            let totalTSS = value.reduce(into: 0) { $0 + $1.targetLoad}
            return (weekStart: key, missions: value.sorted(by: { $0.date < $1.date }), totalLoad: totalTSS)
        }.sorted { $0.weekStart < $1.weekStart }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // SYSTEM HEADER
            HStack {
                Text("STRATEGIC PHASING")
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
                ContentUnavailableView(
                    "NO MISSIONS SCHEDULED",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Inject directives to establish the macro-cycle.")
                )
                .foregroundStyle(ColorTheme.surfaceBorder)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // 📈 THE LOAD TRAJECTORY CHART
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PLANNED LOAD TRAJECTORY (TSS)")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            
                            Chart(upcomingMissions) { mission in
                                BarMark(
                                    x: .value("Date", mission.date, unit: .day),
                                    y: .value("TSS", mission.targetLoad)
                                )
                                .foregroundStyle(ColorTheme.prime.gradient)
                                .cornerRadius(4)
                            }
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                }
                            }
                            .frame(height: 120)
                        }
                        .padding(20)
                        .background(ColorTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        
                        // 🗓️ THE MICRO-CYCLE GROUPS
                        LazyVStack(spacing: 24) {
                            ForEach(microCycles, id: \.weekStart) { cycle in
                                VStack(alignment: .leading, spacing: 12) {
                                    
                                    // Micro-Cycle Header
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("WEEK OF")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundStyle(ColorTheme.textMuted)
                                            Text(cycle.weekStart.formatted(.dateTime.month(.wide).day().year()))
                                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                                .foregroundStyle(ColorTheme.textPrimary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("AGGREGATE LOAD")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundStyle(ColorTheme.textMuted)
                                            Text("\(Int(cycle.totalLoad)) TSS")
                                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                                .foregroundStyle(ColorTheme.warning)
                                        }
                                    }
                                    
                                    // Directives for this specific week
                                    ForEach(cycle.missions) { mission in
                                        DirectiveRowCard(directive: mission)
                                            .onTapGesture {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                editingMission = mission
                                            }
                                            .contextMenu {
                                                Button(role: .destructive, action: { deleteSingleMission(mission) }) {
                                                    Label("PURGE DIRECTIVE", systemImage: "trash")
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .applyTacticalOS(title: "MACRO-CYCLE STRATEGY", showBack: true)
        
        // FLOATING ACTION BUTTON
        .overlay(alignment: .bottom) {
            Button(action: { showingAddSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("INJECT DIRECTIVE")
                }
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.prime)
                .foregroundStyle(ColorTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: ColorTheme.background.opacity(0.8), radius: 10, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sheet(item: $editingMission) { mission in
            EditMissionSheet(mission: mission)
        }
        .sheet(isPresented: $showingAddSheet) {
            // AddPlannedActivitySheet()
            AddPlannedActivitySheet()
                            .presentationDetents([.large]) // Gives you full screen space to type
        }
    }
    
    // MARK: - ⚙️ LOGIC: PURGE RECORD
    private func deleteSingleMission(_ mission: OperationalDirective) {
        context.delete(mission)
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
    
    @Bindable var mission: OperationalDirective
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("OPERATIONAL PARAMETERS")) {
                    TextField("Activity Designation", text: $mission.activity)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    
                    DatePicker("Execution Time", selection: $mission.date, displayedComponents: [.date, .hourAndMinute])
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                
                // RESTORED: Target Load is critical for periodization calculation
                Section(header: Text("PHYSIOLOGICAL LOAD")) {
                    HStack {
                        Text("TARGET TSS")
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
                
                Section(header: Text("THERMODYNAMIC PROFILE")) {
                    Picker("FUEL TIER", selection: $mission.fuelTier) {
                        Text("Low").tag("LOW")
                        Text("Medium").tag("MED")
                        Text("High").tag("HIGH")
                        Text("Race").tag("RACE")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tint(ColorTheme.prime)
                }
            }
            .applyTacticalOS(title: "RECALIBRATE DIRECTIVE", showBack: false)
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

// MARK: - 🧱 SUB-COMPONENT: DIRECTIVE ROW UI
struct DirectiveRowCard: View {
    let directive: OperationalDirective
    
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
                    Text(directive.date.formatted(date: .abbreviated, time: .shortened).uppercased())
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                    
                    Text(directive.activity.uppercased())
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                Text(directive.fuelTier.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(tierColor.opacity(0.15))
                    .foregroundStyle(tierColor)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(tierColor.opacity(0.5), lineWidth: 1))
            }
            
            // RESTORED: Visualizing the target load for the specific mission
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(directive.targetLoad))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorTheme.prime)
                Text(" PLANNED TSS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
            }
        }
        .padding()
        .background(ColorTheme.surfaceBorder.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
