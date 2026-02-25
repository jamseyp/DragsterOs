import SwiftUI
import SwiftData

// 📐 ARCHITECTURE: A structured data model for race phasing.
struct RacePhase: Identifiable {
    let id = UUID()
    let distance: String
    let mode: String
    let powerTarget: String
    let paceTarget: String
    let rpe: String
    let color: Color
}

struct PaddockView: View {
    // 1. THE SENSOR BRIDGE (Fixed for Swift 6)
    @State private var hkManager = HealthKitManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // 2. THE TACTICAL PLAN (Pulled directly from your CSV strategy)
    private let beaconFellStrategy: [RacePhase] = [
        RacePhase(
            distance: "0km – 3km",
            mode: "REASONABLE (The Discipline)",
            powerTarget: "< 280W",
            paceTarget: "5:50 - 5:55 /km",
            rpe: "Zone 3 | RPE 6-7 (Nose breathing hard)",
            color: .cyan
        ),
        RacePhase(
            distance: "4km – 8km",
            mode: "CONTROLLABLE HARD (The Grind)",
            powerTarget: "285 - 295W",
            paceTarget: "5:40 - 5:45 /km",
            rpe: "Zone 4 | Threshold (Focus on Cadence)",
            color: .yellow
        ),
        RacePhase(
            distance: "8km – 10km",
            mode: "EMPTY THE TANK (The Kill)",
            powerTarget: "300W+",
            paceTarget: "< 5:35 /km",
            rpe: "Zone 5 | RPE 10 (Hold the line)",
            color: .red
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    
                    // 1️⃣ THE HEADER
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PREDICTIVE STRATEGY")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.gray)
                        Text("BEACON FELL 10K")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("TARGET FINISH: SUB-58 MINUTES")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.purple)
                            .padding(.top, 4)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // 2️⃣ LIVE PRE-RACE BIOMETRICS
                    // Upgraded your original sensor view into a premium glassmorphic card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PRE-RACE SENSOR CHECK")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(.gray)
                        
                        HStack(alignment: .center, spacing: 20) {
                            // Pulsing Heart Icon
                            Image(systemName: "heart.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.red)
                                .shadow(color: .red.opacity(0.5), radius: 8)
                                .symbolEffect(.pulse, options: .repeating)
                            
                            VStack(alignment: .leading) {
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    // Live Heart Rate
                                    // NOTE: This assumes you added a `latestHR` property to HealthKitManager.
                                    // If not, it defaults to "--" until we map the live workout session.
                                    Text("--")
                                        .font(.system(size: 48, weight: .heavy, design: .monospaced))
                                        .foregroundStyle(.white)
                                        .contentTransition(.numericText())
                                    Text("BPM")
                                        .font(.caption.bold())
                                        .foregroundStyle(.gray)
                                }
                                Text("AWAITING APPLE WATCH CONNECTION")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.cyan)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // 3️⃣ THE TACTICAL SPLITS
                    VStack(alignment: .leading, spacing: 16) {
                        Text("EXECUTION PHASES")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.gray)
                            .padding(.horizontal)
                        
                        ForEach(beaconFellStrategy) { phase in
                            PhaseCard(phase: phase)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        // ✨ THE POLISH: Modern navigation configuration
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topLeading) {
            // Modern, tactile back button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.gray.opacity(0.5), .black)
                    .padding()
            }
        }
    }
}

// 🎨 THE CANVAS: Reusable UI Component for Pacing Phases
struct PhaseCard: View {
    let phase: RacePhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(phase.distance)
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(phase.color)
                Spacer()
                Text(phase.paceTarget)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            
            Text(phase.mode)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            
            HStack(spacing: 12) {
                Label(phase.powerTarget, systemImage: "bolt.fill")
                    .foregroundStyle(.yellow)
                Label(phase.rpe, systemImage: "lungs.fill")
                    .foregroundStyle(.gray)
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(phase.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
