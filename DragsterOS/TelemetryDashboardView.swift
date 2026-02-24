// TelemetryDashboardView.swift
// DragsterOS - High-Performance Telemetry

import SwiftUI

struct TelemetryDashboardView: View {
    @StateObject var engine = TelemetryManager()
    
    var body: some View {
        ZStack {
            // The "Pure Black" Canvas
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // --- HEADER SECTION ---
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MORNING TELEMETRY")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        // A subtle accent line to define the section
                        Rectangle()
                            .fill(Color.cyan)
                            .frame(width: 40, height: 3)
                    }
                    .padding(.top, 20)
                    
                    // --- HERO INSTRUMENT ---
                    // Centering the Readiness Gauge for maximum impact
                    HStack {
                        Spacer()
                        ReadinessGauge(score: Double(engine.currentReport.readinessScore))
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    
                    // --- TELEMETRY GRID ---
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
        .navigationBarHidden(true) // We use our custom header for a more "embedded" look
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
