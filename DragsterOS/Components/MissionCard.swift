//
//  MissionCard.swift
//  DragsterOS
//
//  Created by James Parker on 24/02/2026.
//

import SwiftUI

// ✨ THE POLISH: A reusable, highly-styled glassmorphic container for mission data
struct MissionCard<Content: View>: View {
    var title: String
    var icon: String
    var color: Color
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 12, weight: .black, design: .monospaced))
            .foregroundStyle(color)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.white.opacity(0.05)) // Subtle glass effect against black
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
