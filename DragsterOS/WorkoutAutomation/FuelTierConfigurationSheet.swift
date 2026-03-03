//
//  FuelTierConfigurationSheet.swift
//  DragsterOS
//
//  Created by James Parker on 27/02/2026.
//


import SwiftUI

// MARK: - 🎛️ FUEL TIER CONFIGURATION COMMAND
struct FuelTierConfigurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // State variables for each tier
    @State private var lowTarget = MacroTarget(protein: 0, carbs: 0, fat: 0)
    @State private var medTarget = MacroTarget(protein: 0, carbs: 0, fat: 0)
    @State private var highTarget = MacroTarget(protein: 0, carbs: 0, fat: 0)
    @State private var raceTarget = MacroTarget(protein: 0, carbs: 0, fat: 0)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    Text("OVERRIDE DEFAULT MACRONUTRIENT MULTIPLIERS. CHANGES APPLY IMMEDIATELY TO THE THERMODYNAMIC ENGINE.")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.warning)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    TierEditorCard(title: "LOW / MAINTENANCE", target: $lowTarget, color: .green)
                    TierEditorCard(title: "MEDIUM / TEMPO", target: $medTarget, color: .yellow)
                    TierEditorCard(title: "HIGH / CARB LOAD", target: $highTarget, color: .orange)
                    TierEditorCard(title: "RACE / GLYCOGEN MAX", target: $raceTarget, color: ColorTheme.critical)
                    
                }
                .padding(.bottom, 40)
            }
            .applyTacticalOS(title: "FUEL CALIBRATION", showBack: false)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("CANCEL") { dismiss() }
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("SAVE") {
                        saveConfiguration()
                    }
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                }
            }
            .onAppear {
                loadCurrentConfiguration()
            }
        }
    }
    
    // MARK: - ⚙️ LOGIC
    private func loadCurrentConfiguration() {
        lowTarget = NutritionEngine.getTarget(for: "LOW")
        medTarget = NutritionEngine.getTarget(for: "MED")
        highTarget = NutritionEngine.getTarget(for: "HIGH")
        raceTarget = NutritionEngine.getTarget(for: "RACE")
    }
    
    private func saveConfiguration() {
        NutritionEngine.saveTarget(lowTarget, for: "LOW")
        NutritionEngine.saveTarget(medTarget, for: "MED")
        NutritionEngine.saveTarget(highTarget, for: "HIGH")
        NutritionEngine.saveTarget(raceTarget, for: "RACE")
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        dismiss()
    }
}

// MARK: - 🧱 SUB-COMPONENT: TIER EDITOR CARD
struct TierEditorCard: View {
    let title: String
    @Binding var target: MacroTarget
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(color)
                
                Spacer()
                
                Text("\(Int(target.calories)) KCAL")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
            }
            
            HStack(spacing: 12) {
                MacroInputField(label: "PRO (g)", value: $target.protein)
                MacroInputField(label: "CARB (g)", value: $target.carbs)
                MacroInputField(label: "FAT (g)", value: $target.fat)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct MacroInputField: View {
    let label: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(ColorTheme.textPrimary)
                .padding(8)
                .background(ColorTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ColorTheme.surfaceBorder, lineWidth: 1))
        }
    }
}