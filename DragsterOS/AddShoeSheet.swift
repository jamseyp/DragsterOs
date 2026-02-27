import SwiftUI
import SwiftData

struct AddShoeSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 🕹️ STATE
    @State private var brand = ""
    @State private var model = ""
    @State private var startingMileage: Double = 0.0
    @State private var lifespan: Double = 800
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ColorTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. HEADER (Since we are skipping the buggy toolbar)
                HStack {
                    Text("COMMISSION CHASSIS")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                }
                .padding()
                .background(ColorTheme.surface)
                
                Form {
                    Section(header: Text("SPECIFICATIONS")) {
                        TextField("Brand (e.g. Nike)", text: $brand)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                        TextField("Model (e.g. Alphafly 3)", text: $model)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                    }
                    
                    Section(header: Text("LIFECYCLE TARGET")) {
                        HStack {
                            Text("STARTING KM")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            Spacer()
                            TextField("0", value: $startingMileage, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                        
                        HStack {
                            Text("MAX KM")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            Spacer()
                            TextField("800", value: $lifespan, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                        }
                    }
                }
                .scrollContentBackground(.hidden) // Shows our custom background
            }
            
            // 2. TACTICAL ACTION FOOTER
            VStack(spacing: 12) {
                Divider().background(ColorTheme.surfaceBorder)
                
                Button(action: { saveNewShoe() }) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("AUTHORIZE DEPLOYMENT")
                    }
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(brand.isEmpty || model.isEmpty ? ColorTheme.textMuted : ColorTheme.prime)
                    .foregroundStyle(ColorTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(brand.isEmpty || model.isEmpty)
                
                Button("ABORT SEQUENCE") { dismiss() }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.critical)
                    .padding(.bottom, 10)
            }
            .padding(24)
            .background(ColorTheme.surface.shadow(radius: 10))
        }
    }
    
    // MARK: - ⚙️ LOGIC
    private func saveNewShoe() {
        let newShoe = RunningShoe(
            brand: brand,
            model: model,
            currentMileage: startingMileage,
            maxLifespan: lifespan
        )
        
        context.insert(newShoe)
        
        do {
            try context.save()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            dismiss()
        } catch {
            print("🚨 DATA INSERTION REFUSED: \(error.localizedDescription)")
        }
    }
}
