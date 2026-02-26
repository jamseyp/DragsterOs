//
//  BiomechanicsEfficiencyChart.swift
//  DragsterOS
//
//  Created by James Parker on 26/02/2026.
//


import SwiftUI
import Charts

struct BiomechanicsEfficiencyChart: View {
    let gct: Double
    let oscillation: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MECHANICAL EFFICIENCY VECTORS")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            
            HStack(spacing: 20) {
                // GCT Gauge
                VStack(alignment: .leading) {
                    Text("\(Int(gct))ms")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(gct > 260 ? ColorTheme.critical : .cyan)
                    Text("GROUND CONTACT")
                        .font(.system(size: 8, weight: .bold)).foregroundStyle(ColorTheme.textMuted)
                }
                
                // Oscillation Gauge
                VStack(alignment: .leading) {
                    Text(String(format: "%.1fcm", oscillation))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(oscillation > 10 ? .orange : .green)
                    Text("VERT. OSCILLATION")
                        .font(.system(size: 8, weight: .bold)).foregroundStyle(ColorTheme.textMuted)
                }
            }
            
            // Visual Indicator Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(ColorTheme.surfaceBorder).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [.green, .orange, .red], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(min(1.0, gct/400.0)), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}