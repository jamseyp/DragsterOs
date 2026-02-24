import SwiftUI
import CoreData

struct GarageLogView: View {
    // 1. DATABASE CONNECTION
    @Environment(\.managedObjectContext) private var viewContext

    // 2. MODERN FETCH REQUEST
    // Using the modern Swift SortDescriptor prevents Objective-C keypath crashes
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.date, order: .reverse)],
        animation: .default)
    private var entries: FetchedResults<LogEntry>

    var body: some View {
        ZStack {
            // The Pure Black Canvas
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading) {
                Text("GARAGE LOG")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                
                if entries.isEmpty {
                    Spacer()
                    Text("NO TELEMETRY SAVED YET")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    List {
                        ForEach(entries, id: \.self) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.date ?? Date(), formatter: logDateFormatter)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                        .tracking(1.0)
                                    
                                    HStack(spacing: 12) {
                                        // Using String(format:) completely resolves the SwiftUI compiler ambiguity
                                        Text(String(format: "HRV: %.1f", entry.hrv))
                                        Text(String(format: "SLP: %.1f", entry.sleep))
                                        Text(String(format: "SOR: %.1f", entry.soreness))
                                    }
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                }
                                Spacer()
                                
                                // The Final Score
                                Text(String(format: "%.1f", entry.score))
                                    .font(.system(size: 24, weight: .black, design: .monospaced))
                                    .foregroundColor(statusColor(for: entry.score))
                                    .shadow(color: statusColor(for: entry.score).opacity(0.3), radius: 5, x: 0, y: 0)
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color(white: 0.12)) // Dark mode row base
                            .listRowSeparator(.hidden) // Removes the default grey lines for a cleaner look
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    // .plain is safer across all iOS deployment targets than .scrollContentBackground
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Abstracted logic for cleaner Views
    private func statusColor(for score: Double) -> Color {
        if score >= 7.5 { return .green }
        if score >= 5.0 { return .orange }
        return .red
    }
    
    // Deletion Protocol with fluid animation
    private func deleteEntries(offsets: IndexSet) {
        // Using a custom spring animation makes the deletion feel mechanical and physical
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offsets.map { entries[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("System Error: Could not delete data.")
            }
        }
    }
}

// Formatter for the date text
private let logDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM dd - HH:mm"
    return formatter
}()
