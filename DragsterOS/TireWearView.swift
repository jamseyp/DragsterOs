import SwiftUI
import SwiftData

// MARK: - 🗺️ INVENTORY ROOT
/// The visual inventory for all active footwear. Uses dynamic progress bars
/// and semantic color shifting to signal structural degradation.
struct TireWearView: View {
    @Environment(\.modelContext) private var context
    
    // Fetch active equipment, prioritized by the highest mileage (structural wear)
    @Query(filter: #Predicate<RunningShoe> { $0.isActive }, sort: \RunningShoe.currentMileage, order: .reverse)
    private var activeShoes: [RunningShoe]
    
    @State private var showingAddShoeSheet = false
    
    var body: some View {
        ZStack {
            // Theme-aware background (Aluminum in Light / OLED in Dark)
            ColorTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // --- SECTION: HEADER ---
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EQUIPMENT INVENTORY")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        Text("STRUCTURAL INTEGRITY")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(ColorTheme.textPrimary)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // --- SECTION: INVENTORY LIST ---
                    if activeShoes.isEmpty {
                        ContentUnavailableView(
                            "NO EQUIPMENT LOGGED",
                            systemImage: "shoe.2",
                            description: Text("Initialize your footwear rotation to begin tracking degradation.")
                        )
                        .foregroundStyle(ColorTheme.prime)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(activeShoes) { shoe in
                                ShoeDegradationCard(shoe: shoe)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("INVENTORY")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingAddShoeSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(ColorTheme.prime)
                }
            }
        }
        .sheet(isPresented: $showingAddShoeSheet) {
            AddShoeSheet()
        }
    }
}

// MARK: - 📦 COMPONENT: DEGRADATION CARD
struct ShoeDegradationCard: View {
    @Bindable var shoe: RunningShoe
    @State private var animatedWidth: CGFloat = 0
    
    // Maps the integrity ratio to the semantic color palette
    private var healthColor: Color {
        let ratio = shoe.currentMileage / shoe.maxLifespan
        if ratio < 0.6 { return ColorTheme.recovery }   // Fresh
        if ratio < 0.85 { return ColorTheme.warning }   // Mid-life
        return ColorTheme.critical                      // Critical
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. Identity & Status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shoe.model.uppercased()) // Adjusted to .model property
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                    
                    HStack {
                        Text(shoe.brand.uppercased())
                        Text("•")
                        Text(shoe.purpose.uppercased())
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                }
                
                Spacer()
                
                // 2. Numerical Telemetry
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(shoe.currentMileage))")
                            .font(.system(size: 24, weight: .heavy, design: .monospaced))
                            .foregroundStyle(healthColor)
                        Text("KM")
                            .font(.caption2.bold())
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                    Text("OF \(Int(shoe.maxLifespan)) KM")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
            }
            
            // 3. Fluid Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorTheme.textPrimary.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(healthColor)
                        .frame(width: animatedWidth, height: 8)
                        .shadow(color: (shoe.currentMileage / shoe.maxLifespan) > 0.85 ? ColorTheme.critical.opacity(0.5) : .clear, radius: 4)
                }
                .onAppear {
                    let ratio = CGFloat(shoe.currentMileage / shoe.maxLifespan)
                    let targetWidth = geometry.size.width * min(ratio, 1.0)
                    
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        animatedWidth = targetWidth
                    }
                }
            }
            .frame(height: 8)
            
            // 4. Tactical Warning
            if (shoe.currentMileage / shoe.maxLifespan) > 0.85 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("CRITICAL WEAR: RISK OF INJURY DETECTED.")
                }
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(ColorTheme.critical)
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(healthColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 🎨 SHEET: INITIALIZE EQUIPMENT
struct AddShoeSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var brand: String = ""
    @State private var model: String = ""
    @State private var terrain: String = "Road"
    @State private var purpose: String = "Daily"
    @State private var currentMileage: Double = 0.0
    
    let terrains = ["Road", "Trail", "Track"]
    let purposes = ["Recovery", "Daily", "Speed", "Race"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("SPECIFICATIONS").font(.caption.monospaced())) {
                        TextField("Brand (e.g., Nike)", text: $brand)
                            .foregroundStyle(ColorTheme.textPrimary)
                        
                        TextField("Model (e.g., Vaporfly 3)", text: $model)
                            .foregroundStyle(ColorTheme.textPrimary)
                        
                        Picker("Terrain", selection: $terrain) {
                            ForEach(terrains, id: \.self) { Text($0) }
                        }
                        
                        Picker("Purpose", selection: $purpose) {
                            ForEach(purposes, id: \.self) { Text($0) }
                        }
                    }
                    .listRowBackground(ColorTheme.panel)
                    
                    Section(header: Text("STRUCTURAL HISTORY").font(.caption.monospaced())) {
                        VStack(alignment: .leading) {
                            Text("\(Int(currentMileage)) KM ON CHASSIS")
                                .font(.system(.body, design: .monospaced, weight: .bold))
                                .foregroundStyle(ColorTheme.prime)
                            
                            Slider(value: $currentMileage, in: 0...500, step: 1)
                        }
                    }
                    .listRowBackground(ColorTheme.panel)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("INITIALIZE CHASSIS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("ABORT") { dismiss() }
                        .foregroundStyle(ColorTheme.textMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("ENGAGE") { saveShoe() }
                        .foregroundStyle(ColorTheme.prime)
                        .font(.caption.bold().monospaced())
                        .disabled(brand.isEmpty || model.isEmpty)
                }
            }
        }
    }
    
    private func saveShoe() {
        let newShoe = RunningShoe(
            brand: brand,
            model: model,
            terrainType: terrain,
            purpose: purpose,
            currentMileage: currentMileage
        )
        
        context.insert(newShoe)
        try? context.save()
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        dismiss()
    }
}
