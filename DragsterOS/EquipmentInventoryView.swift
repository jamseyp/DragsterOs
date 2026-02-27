import SwiftUI
import SwiftData

// MARK: - 👟 EQUIPMENT INVENTORY COMMAND (V1.2)
struct EquipmentInventoryView: View {
    @Environment(\.modelContext) private var context
    
    // Fetch all shoes, newest/most used first
    @Query(sort: \RunningShoe.model, order: .forward) private var shoes: [RunningShoe]
    @Query private var sessions: [KineticSession]
    
    @State private var showingAddSheet = false
    @State private var editingShoe: RunningShoe?
    @State private var isSyncing = false
    
    // 🧠 Logic: Split the fleet for better scannability
    private var activeFleet: [RunningShoe] { shoes.filter { $0.isActive } }
    private var retiredFleet: [RunningShoe] { shoes.filter { !$0.isActive } }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // 1. FLEET STATUS SUMMARY
                HStack(spacing: 12) {
                    FleetStatCard(label: "ACTIVE CHASSIS", value: "\(activeFleet.count)", color: ColorTheme.prime)
                    FleetStatCard(label: "TOTAL FLEET KM", value: "\(Int(shoes.reduce(0) { $0 + $1.currentMileage }))", color: .cyan)
                }
                .padding(.horizontal)
                
                // 2. ACTIVE DEPLOYMENT ZONE
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("ACTIVE DEPLOYMENT")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        Spacer()
                        // ✨ SYNC BUTTON: Automates mileage calculation
                        Button(action: { syncAllShoeMileage() }) {
                            Label(isSyncing ? "SYNCING..." : "SYNC ODOMETERS", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .disabled(isSyncing)
                    }
                    
                    if activeFleet.isEmpty {
                        Text("NO ACTIVE CHASSIS DETECTED")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.surfaceBorder)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(activeFleet) { shoe in
                            ShoeDataCard(shoe: shoe)
                                .onTapGesture { editingShoe = shoe }
                        }
                    }
                }
                .padding(.horizontal)
                
                // 3. RETIRED / ARCHIVED
                if !retiredFleet.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("RETIRED ASSETS")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                        
                        ForEach(retiredFleet) { shoe in
                            ShoeDataCard(shoe: shoe)
                                .opacity(0.6)
                                .onTapGesture { editingShoe = shoe }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
        .applyTacticalOS(title: "FLEET MANAGEMENT", showBack: true)
        .overlay(alignment: .bottom) {
            Button(action: { showingAddSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("COMMISSION NEW CHASSIS")
                }
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.prime)
                .foregroundStyle(ColorTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showingAddSheet) { AddShoeSheet() }
        .sheet(item: $editingShoe) { shoe in EditShoeSheet(shoe: shoe) }
    }
    
    // MARK: - ⚙️ ODOMETER SYNC LOGIC
    /// Iterates through every KineticSession and aggregates distance for each shoe.
    private func syncAllShoeMileage() {
        isSyncing = true
        
        for shoe in shoes {
            // Find ONLY sessions for this shoe that haven't been counted yet
            let newSessions = sessions.filter {
                $0.shoeName == shoe.model && $0.isSyncedToEquipment == false
            }
            
            let newDistance = newSessions.reduce(0.0) { $0 + $1.distanceKM }
            
            // 1. Just add it to the current value
            shoe.currentMileage += newDistance
            
            // 2. Mark sessions as "Done" so they aren't added again next time
            for session in newSessions {
                session.isSyncedToEquipment = true
            }
        }
        
        try? context.save()
        isSyncing = false
    }
    
    // MARK: - 🧱 SUB-COMPONENTS
    
    struct FleetStatCard: View {
        let label: String; let value: String; let color: Color
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
                Text(value).font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundStyle(color)
            }
            .padding().frame(maxWidth: .infinity, alignment: .leading).background(ColorTheme.surface).clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    struct ShoeDataCard: View {
        let shoe: RunningShoe
        var health: Double { shoe.maxLifespan > 0 ? min(shoe.currentMileage / shoe.maxLifespan, 1.0) : 0 }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shoe.brand.uppercased()).font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
                        Text(shoe.model.uppercased()).font(.system(size: 14, weight: .heavy, design: .monospaced))
                    }
                    Spacer()
                    // Visual Indicator for 'Retired' status
                    if !shoe.isActive {
                        Text("ARCHIVED").font(.system(size: 8, weight: .black, design: .monospaced)).padding(4).background(ColorTheme.surfaceBorder).clipShape(Capsule())
                    }
                }
                
                // Tactical Gauge
                VStack(alignment: .trailing, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2).fill(ColorTheme.background)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(health > 0.9 ? ColorTheme.critical : (health > 0.75 ? Color.orange : ColorTheme.prime))
                                .frame(width: geo.size.width * health)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack(spacing: 2) {
                        Text("\(Int(shoe.currentMileage))").font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("/ \(Int(shoe.maxLifespan)) KM").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
                    }
                }
            }
            .padding().background(ColorTheme.surface).clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(health > 0.9 && shoe.isActive ? ColorTheme.critical : Color.clear, lineWidth: 1))
        }
    }
    
    
    // MARK: - 🛠️ EDIT SHOE PROTOCOL
    struct EditShoeSheet: View {
        @Environment(\.modelContext) private var context
        @Environment(\.dismiss) private var dismiss
        @Bindable var shoe: RunningShoe
        
        var body: some View {
            NavigationStack {
                Form {
                    Section("IDENTITY") {
                        TextField("Brand", text: $shoe.brand)
                        TextField("Model", text: $shoe.model)
                    }
                    
                    Section("LIFECYCLE") {
                        HStack {
                            Text("TOTAL KM")
                            Spacer()
                            TextField("KM", value: $shoe.currentMileage, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        HStack {
                            Text("MAX THRESHOLD")
                            Spacer()
                            TextField("KM", value: $shoe.maxLifespan, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    Section {
                        Toggle("ACTIVE DEPLOYMENT", isOn: $shoe.isActive)
                    }
                }
                .applyTacticalOS(title: "CALIBRATE CHASSIS", showBack: false)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("COMMIT") {
                            try? context.save()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
