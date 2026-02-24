// TelemetryDashboardView.swift
import SwiftUI

struct TelemetryDashboardView: View {
    @StateObject var engine = TelemetryManager()
    
    // 1. THE NAVIGATION CONTROLLER
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // 2. THE CUSTOM BACK BUTTON
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("DASHBOARD")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    }
                    
                    // --- HEADER SECTION ---
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MORNING TELEMETRY")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        Rectangle()
                            .fill(Color.cyan)
                            .frame(width: 40, height: 3)
                    }
                    // ... the rest of your view remains exactly the same ...
                    
                    // Center the Readiness Gauge
                    HStack {
                        Spacer()
                        ReadinessGauge(score: Double(engine.currentReport.readinessScore))
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    // Telemetry Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricCard(title: "RESTING HR", value: "\(engine.currentReport.restingHR) BPM", color: .red)
                        MetricCard(title: "HRV BIAS", value: engine.currentReport.hrvStatus, color: .blue)
                        MetricCard(title: "TOP PACE", value: engine.currentReport.intervalPace, color: .yellow)
                        MetricCard(title: "MAX POWER", value: "\(engine.currentReport.maxPower)W", color: .orange)
                        MetricCard(title: "CADENCE", value: "\(engine.currentReport.averageCadence) SPM", color: .purple)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarHidden(true)
    }
}

// Reusable UI Component for the Grid
// A Refined, High-Contrast Metric Card
struct MetricCard: View {
    var title: String
    var value: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            
            Text(title)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.gray.opacity(0.8))
                .tracking(1.5) // Increased letter spacing for that "instrument" look
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.08)) // Deeper black for higher contrast
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(white: 0.15), lineWidth: 1) // Subtle border definition
                )
        )
    }
}
