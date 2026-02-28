//
//  IngestionTerminalView.swift
//  DragsterOS
//
//  Created by James Parker on 28/02/2026.
//


import SwiftUI
import SwiftData

struct IngestionTerminalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var jsonInput: String = ""
    @State private var statusMessage: String = "Awaiting JSON Payload..."
    @State private var isSuccess: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(statusMessage)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(isSuccess ? .green : ColorTheme.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                TextEditor(text: $jsonInput)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.prime.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal)
                
                Button(action: processPayload) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Ingest Training Block")
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.background)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(jsonInput.isEmpty ? ColorTheme.textMuted : ColorTheme.prime)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(jsonInput.isEmpty)
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("Data Ingestion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func processPayload() {
        do {
            let count = try MissionIngestionService.shared.ingest(jsonString: jsonInput, context: context)
            statusMessage = "SUCCESS: \(count) Missions Authorized."
            isSuccess = true
            jsonInput = "" // Clear the terminal
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            statusMessage = "FAULT: \(error.localizedDescription)"
            isSuccess = false
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}