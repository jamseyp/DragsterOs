import SwiftUI
import CoreData

struct GarageLogView: View {
    // 1. DATABASE CONNECTION
    @Environment(\.managedObjectContext) private var viewContext

    // 2. FETCH THE LOGS (Sorted by newest first)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LogEntry.date, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<LogEntry>

    var body: some View {
        ZStack {
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
                        ForEach(entries) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    // Format the date to look like a racing log (e.g., "FEB 24 - 10:30 AM")
                                    Text(entry.date ?? Date(), formatter: logDateFormatter)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                    
                                    HStack(spacing: 12) {
                                        Text("HRV: \(entry.hrv, specifier: "%.1f")")
                                        Text("SLP: \(entry.sleep, specifier: "%.1f")")
                                        Text("SOR: \(entry.soreness, specifier: "%.1f")")
                                    }
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                }
                                Spacer()
                                
                                // The Final Score
                                Text(String(format: "%.1f", entry.score))
                                    .font(.system(size: 24, weight: .black, design: .monospaced))
                                    // Make it green if above 7.5, orange if > 5, else red
                                    .foregroundColor(entry.score > 7.5 ? .green : (entry.score > 5.0 ? .orange : .red))
                            }
                            .padding(.vertical, 5)
                            .listRowBackground(Color(white: 0.15)) // Dark mode list rows
                        }
                        .onDelete(perform: deleteEntries) // Swipe to delete!
                    }
                    .scrollContentBackground(.hidden) // Removes default iOS list styling
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Engine Function: Swipe to delete a bad entry
    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("❌ Engine Fault: Could not delete data.")
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
