//
//  AddShoeSheet.swift
//  DragsterOS
//
//  Created by James Parker on 27/02/2026.
//
import SwiftUI
import SwiftData

struct AddShoeSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var brand = ""
    @State private var model = ""
    @State private var lifespan: Double = 800
    
    var body: some View {
        NavigationStack {
            Form {
                Section("SPECIFICATIONS") {
                    TextField("Brand (e.g. Nike)", text: $brand)
                    TextField("Model (e.g. Alphafly 3)", text: $model)
                }
                Section("LIFECYCLE TARGET") {
                    HStack {
                        Text("MAX KM")
                        Spacer()
                        TextField("800", value: $lifespan, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            .applyTacticalOS(title: "COMMISSION CHASSIS", showBack: false)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("ABORT") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("CONFIRM") {
                        let newShoe = RunningShoe(brand: brand, model: model, maxLifespan: lifespan)
                        context.insert(newShoe)
                        dismiss()
                    }
                    .disabled(brand.isEmpty || model.isEmpty)
                }
            }
        }
    }
}
