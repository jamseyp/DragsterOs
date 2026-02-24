//
//  PaddockView.swift
//  DragsterOS
//
//  Created by James Parker on 24/02/2026.
//

import SwiftUI

struct PaddockView: View {
    @StateObject var hkManager = HealthKitManager()
    
    // 1. THE NAVIGATION CONTROLLER
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // Central Content
                VStack(spacing: 30) {
                    Text("LIVE SENSOR DATA")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 10) {
                        Text("HEART RATE")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text(hkManager.latestHR > 0 ? "\(Int(hkManager.latestHR))" : "--")
                                .font(.system(size: 60, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("BPM")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        }
                        
                        Text("SOURCE: \(hkManager.sensorName)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(white: 0.2))
                            .cornerRadius(5)
                            .foregroundColor(.gray)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(white: 0.2), lineWidth: 1)
                    )
                    
                    Button(action: { hkManager.requestAuthorization() }) {
                        Text("CALIBRATE SENSORS")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
