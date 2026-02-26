import SwiftUI
import SwiftData

struct ChassisLogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChassisLog.date, order: .reverse) private var chassisHistory: [ChassisLog]
    
    @State private var showingEntrySheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 1. CURRENT HARDWARE STATUS
                if let latest = chassisHistory.first {
                    HStack(spacing: 16) {
                        MetricBlock(label: "PARITY INDEX", value: String(format: "%.1f%%", latest.parityIndex), color: latest.parityIndex > 95 ? .green : .orange)
                        MetricBlock(label: "PWR:MASS", value: String(format: "%.2f", latest.powerToWeight), color: ColorTheme.prime)
                    }
                    .padding(.horizontal)
                }
                
                // 2. LOG ENTRY TRIGGER
                Button(action: { showingEntrySheet = true }) {
                    HStack {
                        Image(systemName: "gauge.with.needle.fill")
                        Text("INITIATE HARDWARE SCAN")
                    }
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.prime)
                    .foregroundStyle(ColorTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                // 3. HISTORICAL TRENDS (With Swipe-to-Delete)
                VStack(alignment: .leading, spacing: 16) {
                    Text("DIAGNOSTIC HISTORY")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                        .padding(.horizontal)
                    
                    // ✨ Using a LazyVStack for the history list
                    LazyVStack(spacing: 12) {
                        ForEach(chassisHistory, id: \.self) { log in
                            ChassisHistoryRow(log: log)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteLog(log)
                                    } label: {
                                        Label("Purge Entry", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteLog(log)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 20)
        }
        .applyTacticalOS(title: "CHASSIS & EFFICIENCY")
        .sheet(isPresented: $showingEntrySheet) {
            HardwareScanSheet()
        }
    }
    
    private func deleteLog(_ log: ChassisLog) {
        context.delete(log)
        try? context.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// ✨ REFACTOR: Extracted Row Component for cleaner deletion logic
struct ChassisHistoryRow: View {
    let log: ChassisLog
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(log.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 14, weight: .bold))
                Text("L: \(log.leftThighCirc, specifier: "%.1f")cm | R: \(log.rightThighCirc, specifier: "%.1f")cm")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
            }
            Spacer()
            Text("\(log.maxWattage)W")
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(ColorTheme.prime)
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Reusable Metric Block for consistency
struct MetricBlock: View {
    var label: String
    var value: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
