import SwiftUI
import SwiftData

struct MicrocycleBuilderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // Grab the singleton registry
    @Query private var registries: [UserRegistry]
    
    let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    @State private var weeklySkeleton: [Int: [BlueprintSlot]] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // ... (Keep your existing Instruction Header and Day-By-Day Builder UI loops exactly the same) ...
                        
                        // SKELETON UI LOOP
                        ForEach(0..<7, id: \.self) { dayIndex in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(daysOfWeek[dayIndex].uppercased())
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(ColorTheme.textPrimary)
                                    Spacer()
                                    Button { addSlot(to: dayIndex) } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(ColorTheme.prime).font(.title3)
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                VStack(spacing: 8) {
                                    if let slots = weeklySkeleton[dayIndex], !slots.isEmpty {
                                        ForEach(slots.indices, id: \.self) { slotIndex in
                                            BlueprintRow(
                                                slot: binding(for: dayIndex, slotIndex: slotIndex),
                                                onDelete: { removeSlot(dayIndex: dayIndex, slotIndex: slotIndex) }
                                            )
                                        }
                                    } else {
                                        Text("REST DAY")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundStyle(ColorTheme.textMuted)
                                            .padding(.horizontal, 16).padding(.vertical, 8)
                                    }
                                }
                                Divider().background(ColorTheme.surfaceBorder).padding(.top, 8)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Weekly Skeleton")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("SAVE") { saveSkeleton() }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                }
            }
            .onAppear { loadExistingSkeleton() }
        }
    }
    
    // MARK: - Integration Logic
    private func binding(for dayIndex: Int, slotIndex: Int) -> Binding<BlueprintSlot> {
        Binding(get: { weeklySkeleton[dayIndex]![slotIndex] }, set: { weeklySkeleton[dayIndex]![slotIndex] = $0 })
    }
    private func addSlot(to dayIndex: Int) {
        if weeklySkeleton[dayIndex] == nil { weeklySkeleton[dayIndex] = [] }
        weeklySkeleton[dayIndex]?.append(BlueprintSlot(category: .easyRun, timeOfDay: .am))
    }
    private func removeSlot(dayIndex: Int, slotIndex: Int) {
        weeklySkeleton[dayIndex]?.remove(at: slotIndex)
    }
    
    // ✨ THE INTEGRATION: Load and Save directly to SwiftData
    private func loadExistingSkeleton() {
        if let registry = registries.first, !registry.decodedSkeleton.isEmpty {
            weeklySkeleton = registry.decodedSkeleton
        } else {
            // Your default hybrid baseline if completely empty
            weeklySkeleton = [
                0: [.init(category: .easyRun, timeOfDay: .am), .init(category: .strengthUpper, timeOfDay: .pm)],
                1: [.init(category: .recoverySpin, timeOfDay: .am)],
                2: [.init(category: .speedRun, timeOfDay: .am)],
                3: [.init(category: .easyRun, timeOfDay: .am), .init(category: .strengthLower, timeOfDay: .pm)],
                4: [.init(category: .thresholdRun, timeOfDay: .am)],
                5: [.init(category: .easyRun, timeOfDay: .am)],
                6: [.init(category: .longRun, timeOfDay: .am)]
            ]
        }
    }
    
    private func saveSkeleton() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let registry = registries.first else { return }
        
        if let encodedData = try? JSONEncoder().encode(weeklySkeleton) {
            registry.hybridSkeletonData = encodedData
            try? context.save()
        }
        dismiss()
    }
}

// MARK: - Subcomponent: Row UI
struct BlueprintRow: View {
    @Binding var slot: BlueprintSlot
    var onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Time of Day Toggle
            Button {
                slot.timeOfDay = slot.timeOfDay == .am ? .pm : .am
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text(slot.timeOfDay.rawValue)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(slot.timeOfDay == .am ? Color.orange : ColorTheme.prime)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Session Type Picker
            Picker("Session", selection: $slot.category) {
                ForEach(SessionCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .tint(ColorTheme.textPrimary)
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(ColorTheme.critical)
            }
        }
        .padding(12)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}
