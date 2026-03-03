//
//  PlanPreviewCanvas.swift
//  DragsterOS
//
//  Created by James Parker on 28/02/2026.
//

import SwiftUI

/// 🎨 THE CANVAS: A clear, high-contrast overview of the generated Hudson 80/20 training plan.
struct PlanPreviewCanvas: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let generatedPlan: [OperationalDirective]
    let objectiveName: String
    
    @State private var isCommitting = false
    @State private var currentWeekIndex = 0
    
    // 📐 ARCHITECTURE: Sort chronologically and chunk into weeks
    private var weeklyPlan: [[OperationalDirective]] {
        let sorted = generatedPlan.sorted { $0.assignedDate < $1.assignedDate }
        return stride(from: 0, to: sorted.count, by: 7).map {
            Array(sorted[$0 ..< min($0 + 7, sorted.count)])
        }
    }
    
    private var totalTrainingHours: Int {
        let totalMins = generatedPlan.reduce(0) { $0 + $1.workDurationMinutes }
        return totalMins / 60
    }
    
    private var qualitySessionCount: Int {
        generatedPlan.filter { $0.fuelTier == "HIGH" || $0.fuelTier == "RACE" }.count
    }
    
    var body: some View {
        ZStack {
            ColorTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // HEADER
                VStack(spacing: 8) {
                    Text("TRAINING PLAN GENERATED")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                    
                    Text(objectiveName.uppercased())
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                    
                    HStack(spacing: 24) {
                        MetricPill(title: "TOTAL HOURS", value: "\(totalTrainingHours)H")
                        MetricPill(title: "WORKOUTS", value: "\(generatedPlan.count)")
                        MetricPill(title: "QUALITY (20%)", value: "\(qualitySessionCount)")
                    }
                    .padding(.top, 8)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(ColorTheme.surface)
                
                // ✨ WEEK NAVIGATOR
                HStack {
                    Button(action: { withAnimation { currentWeekIndex = max(0, currentWeekIndex - 1) } }) {
                        Image(systemName: "chevron.left.circle.fill").font(.title2)
                    }
                    .disabled(currentWeekIndex == 0)
                    .foregroundStyle(currentWeekIndex == 0 ? ColorTheme.textMuted : ColorTheme.prime)
                    
                    Spacer()
                    
                    Text("WEEK \(currentWeekIndex + 1) OF \(weeklyPlan.count)")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { withAnimation { currentWeekIndex = min(weeklyPlan.count - 1, currentWeekIndex + 1) } }) {
                        Image(systemName: "chevron.right.circle.fill").font(.title2)
                    }
                    .disabled(currentWeekIndex == weeklyPlan.count - 1)
                    .foregroundStyle(currentWeekIndex == weeklyPlan.count - 1 ? ColorTheme.textMuted : ColorTheme.prime)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(ColorTheme.surfaceBorder.opacity(0.2))
                
                // ✨ SWIPABLE TIMELINE PREVIEW
                TabView(selection: $currentWeekIndex) {
                    ForEach(0..<weeklyPlan.count, id: \.self) { weekIndex in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(weeklyPlan[weekIndex]) { mission in
                                    // Using local Preview Card to avoid dependency issues
                                    PreviewMissionCard(directive: mission)
                                }
                            }
                            .padding()
                        }
                        .tag(weekIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // COMMIT FOOTER
                VStack {
                    Button {
                        commitPlanToDatabase()
                    } label: {
                        HStack {
                            if isCommitting {
                                ProgressView().tint(ColorTheme.background)
                            } else {
                                Image(systemName: "calendar.badge.plus")
                                Text("SAVE PLAN TO CALENDAR")
                            }
                        }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ColorTheme.prime)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isCommitting)
                }
                .padding()
                .background(ColorTheme.surface)
            }
        }
        .applyTacticalOS(title: "Plan Preview", showBack: true)
    }
    
    // MARK: - Database Execution
    private func commitPlanToDatabase() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        isCommitting = true
        
        Task {
            for directive in generatedPlan {
                context.insert(directive)
            }
            try? context.save()
            
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                dismiss()
            }
        }
    }
}

// MARK: - 🪪 LOCAL PREVIEW CARD (Read Only)
struct PreviewMissionCard: View {
    let directive: OperationalDirective
    
    private var cleanFuelTier: String { directive.fuelTier.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
    private var isRestDay: Bool { directive.discipline == "REST" }
    
    private var fuelColor: Color {
        switch cleanFuelTier {
        case "LOW": return .green
        case "MED": return .yellow
        case "HIGH": return .orange
        case "RACE": return ColorTheme.critical
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(directive.assignedDate.formatted(date: .abbreviated, time: .omitted).uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.prime)
                Spacer()
                if !isRestDay {
                    Label(cleanFuelTier, systemImage: "fuelpump.fill")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(fuelColor)
                }
            }
            
            HStack {
                Text(directive.missionTitle)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.textPrimary)
                Spacer()
                Image(systemName: isRestDay ? "bed.double.fill" : (directive.discipline == "RUN" ? "figure.run" : "bicycle"))
                    .foregroundStyle(isRestDay ? ColorTheme.textMuted : ColorTheme.prime)
            }
            
            if !isRestDay {
                HStack(spacing: 12) {
                    MetricPill(title: "STRUCTURE", value: "\(directive.intervalSets)x\(directive.workDurationMinutes)m")
                    if directive.discipline != "STRENGTH" {
                        MetricPill(title: "TARGET", value: "\(directive.workTargetWatts)W")
                    }
                    MetricPill(title: "LOAD", value: "\(directive.targetLoad) TSS")
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("COACH'S NOTES")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                Text(directive.coachNotes)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(isRestDay ? Color.gray.opacity(0.1) : ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isRestDay ? Color.clear : ColorTheme.prime.opacity(0.3), lineWidth: 1)
        )
    }
}
