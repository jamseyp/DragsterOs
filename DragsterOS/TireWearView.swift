import SwiftUI
import SwiftData

// 🎨 ARCHITECTURE: The visual inventory for all active footwear.
// We use smooth linear progress bars and strict typographic hierarchy
// to instantly communicate structural degradation.

struct TireWearView: View {
    @Environment(\.modelContext) private var context
    
    // Fetch only active shoes, sorted by most worn
    @Query(filter: #Predicate<RunningShoe> { $0.isActive }, sort: \RunningShoe.currentMileage, order: .reverse)
    private var activeShoes: [RunningShoe]
    
    // ✨ THE FIX: This state variable now properly lives inside the view structure
    @State private var showingAddShoeSheet = false
    
    var body: some View {
        ZStack {
            // Using your customized ColorTheme
            ColorTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // HEADER
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EQUIPMENT INVENTORY")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("STRUCTURAL INTEGRITY")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    if activeShoes.isEmpty {
                        // ✨ THE POLISH: A premium empty state if the database is unpopulated
                        ContentUnavailableView(
                            "NO EQUIPMENT LOGGED",
                            systemImage: "shoe.2",
                            description: Text("Initialize your footwear rotation to begin tracking degradation.")
                        )
                        .foregroundStyle(.cyan)
                    } else {
                        // 1️⃣ THE INVENTORY LIST
                        VStack(spacing: 16) {
                            ForEach(activeShoes) { shoe in
                                ShoeDegradationCard(shoe: shoe)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("INVENTORY")
        .navigationBarTitleDisplayMode(.inline)
        // ✨ THE FIX: Toolbar and Sheet modifiers are now properly attached to the main view body
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingAddShoeSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.cyan)
                }
            }
        }
        .sheet(isPresented: $showingAddShoeSheet) {
            AddShoeSheet()
        }
    }
}

// ✨ THE POLISH: A highly specialized gauge for visualizing foam/carbon wear.
struct ShoeDegradationCard: View {
    @Bindable var shoe: RunningShoe
    @State private var animatedWidth: CGFloat = 0
    
    // Dynamically shift colors based on how close the shoe is to structural failure
    private var healthColor: Color {
        let ratio = shoe.integrityRatio
        switch ratio {
        case 0.0..<0.6: return .cyan    // Prime condition
        case 0.6..<0.85: return .yellow // Mid-life
        default: return .red            // Critical degradation (Time to replace)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. Shoe Metadata
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shoe.name.uppercased())
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    HStack {
                        Text(shoe.terrainType.uppercased())
                        Text("•")
                        Text(shoe.purpose.uppercased())
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.gray)
                }
                
                Spacer()
                
                // 2. Numerical Mileage
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(shoe.currentMileage))")
                            .font(.system(size: 24, weight: .heavy, design: .monospaced))
                            .foregroundStyle(healthColor)
                            .contentTransition(.numericText())
                        Text("KM")
                            .font(.caption2.bold())
                            .foregroundStyle(.gray)
                    }
                    Text("OF \(Int(shoe.maxLifespan)) KM")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.gray)
                }
            }
            
            // 3. The Fluid Degradation Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Animated Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(healthColor)
                        .frame(width: animatedWidth, height: 8)
                        // Add a subtle glow if the shoe is dangerously worn
                        .shadow(color: shoe.integrityRatio > 0.85 ? .red.opacity(0.8) : .clear, radius: 4)
                }
                .onAppear {
                    // Calculate the exact pixel width of the progress bar
                    let targetWidth = geometry.size.width * CGFloat(shoe.integrityRatio)
                    
                    // Spring animation makes the bar "shoot" across the screen on load
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        animatedWidth = targetWidth
                    }
                }
            }
            .frame(height: 8)
            
            // 4. Tactical Warning (Only shows if nearing end of life)
            if shoe.integrityRatio > 0.85 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("CRITICAL WEAR: EVA FOAM DEGRADED. RISK OF INJURY.")
                }
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(.red)
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(healthColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// 🎨 THE CANVAS: The tactile entry form for new equipment.
struct AddShoeSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var terrain: String = "Road"
    @State private var purpose: String = "Speed"
    @State private var currentMileage: Double = 0.0
    
    let terrains = ["Road", "Trail", "Track"]
    let purposes = ["Recovery", "Daily", "Speed", "Race"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("EQUIPMENT IDENTIFICATION").font(.caption.monospaced())) {
                        TextField("Shoe Model (e.g., Boston 12)", text: $name)
                            .foregroundStyle(.white)
                        
                        Picker("Terrain", selection: $terrain) {
                            ForEach(terrains, id: \.self) { Text($0) }
                        }
                        
                        Picker("Tactical Purpose", selection: $purpose) {
                            ForEach(purposes, id: \.self) { Text($0) }
                        }
                    }
                    .listRowBackground(ColorTheme.surface)
                    
                    Section(header: Text("STRUCTURAL WEAR").font(.caption.monospaced())) {
                        VStack(alignment: .leading) {
                            Text("Current Mileage: \(Int(currentMileage)) km")
                                .font(.system(.body, design: .monospaced, weight: .bold))
                                .foregroundStyle(ColorTheme.prime)
                            
                            Slider(value: $currentMileage, in: 0...500, step: 1)
                        }
                    }
                    .listRowBackground(ColorTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("INITIALIZE TIRE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("CANCEL") { dismiss() }
                        .foregroundStyle(ColorTheme.textMuted)
                        .font(.caption.bold().monospaced())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ENGAGE") {
                        saveShoe()
                    }
                    .foregroundStyle(ColorTheme.prime)
                    .font(.caption.bold().monospaced())
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveShoe() {
        let newShoe = RunningShoe(
                    name: name,
                    terrainType: terrain,
                    purpose: purpose,
                    currentMileage: currentMileage,
                    maxLifespan: 500.0 // Default structural limit
                )
                
                // 1. Insert into the context
                context.insert(newShoe)
                
                // 2. Force the engine to write to disk immediately so the UI updates instantly
                try? context.save()
                
                // 3. Tactile feedback and dismiss
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                dismiss()
    }
}
