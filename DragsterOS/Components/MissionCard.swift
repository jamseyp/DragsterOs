//
//  MissionCard.swift
//  DragsterOS
//
//  Created by James Parker on 24/02/2026.
//

import SwiftUI

struct MissionCard: View {
    let mission: String
    let target: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                Text("DAILY MISSION")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.orange)
            }
            
            Text(mission)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text("TARGET:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text(target)
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
