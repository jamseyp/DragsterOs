//
//  AddShoeSheet.swift
//  DragsterOS
//
//  Created by James Parker on 27/02/2026.
//
import SwiftUI
import SwiftData

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
