//
//  TelemetryDashboardView.swift
//  DragsterOS
//
//  Created by James Parker on 24/02/2026.
//
import SwiftUI

struct TelemetryDashboardView: View {
    @StateObject var engine = TelemetryManager()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("MORNING TELEMETRY")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Readiness Gauge
                HStack {
                    Text("READINESS")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(engine.currentReport.readinessScore)/10")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(white: 0.15))
                .cornerRadius(10)
                
                // Performance Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    MetricCard(title: "RESTING HR", value: "\(engine.currentReport.restingHR) BPM", color: .red)
                    MetricCard(title: "HRV BIAS", value: engine.currentReport.hrvStatus, color: .blue)
                    MetricCard(title: "TOP PACE", value: engine.currentReport.intervalPace, color: .yellow)
                    MetricCard(title: "MAX POWER", value: "\(engine.currentReport.maxPower)W", color: .orange)
                    MetricCard(title: "CADENCE", value: "\(engine.currentReport.averageCadence) SPM", color: .purple)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle("Telemetry")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Reusable UI Component for the Grid
struct MetricCard: View {
    var title: String
    var value: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(value)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(color)
                            .lineLimit(1) // Forces it to stay on one line
                            .minimumScaleFactor(0.5) // Shrinks the text up to 50% to make it fit
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(10)
    }
}
