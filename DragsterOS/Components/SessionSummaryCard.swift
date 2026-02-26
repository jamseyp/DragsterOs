//
//  SessionSummaryCard.swift
//  DragsterOS
//
//  Created by James Parker on 26/02/2026.
//


import SwiftUI
import SwiftData

// MARK: - 🃏 COMPONENT: SUMMARY CARD
struct SessionSummaryCard: View {
    let session: KineticSession
    
    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Image(systemName: session.disciplineIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(ColorTheme.background)
            }
            .frame(width: 50, height: 50)
            .background(session.disciplineColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.discipline)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(session.disciplineColor)
                    Spacer()
                    Text(session.date, format: .dateTime.month().day())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
                
                HStack(spacing: 12) {
                    if session.distanceKM > 0 {
                        Text("\(session.distanceKM, specifier: "%.1f") KM")
                    }
                    Text("\(Int(session.durationMinutes)) MIN")
                    Text("RPE \(session.rpe)/10")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(ColorTheme.textPrimary)
            }
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 📦 COMPONENT: TELEMETRY BLOCK
struct TelemetryBlock: View {
    let title: String, value: String, unit: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
            Text(value).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(ColorTheme.textPrimary)
            Text(unit).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ColorTheme.textMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).background(ColorTheme.surface).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - 🔘 COMPONENT: TACTICAL ACTION BUTTON
struct TacticalActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(ColorTheme.background)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 10)
        }
    }
}
