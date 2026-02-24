import SwiftUI

struct PitStopView: View {
    @State private var timeRemaining = 300 // 5 Minutes (300 seconds)
    @State private var isRunning = false
    
    // The Swift Timer Engine
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Convert seconds to MM:SS
    var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("PIT STOP PROTOCOL")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("FOAM ROLL / MOBILITY")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                // THE VISUAL TIMER
                ZStack {
                    Circle()
                        .stroke(lineWidth: 15)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(timeRemaining) / 300.0)
                        .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                        .foregroundColor(timeRemaining < 60 ? .red : .green)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.linear, value: timeRemaining)
                    
                    Text(timeString)
                        .font(.system(size: 60, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                .frame(width: 250, height: 250)
                
                // IGNITION BUTTONS
                HStack(spacing: 30) {
                    Button(action: { isRunning.toggle() }) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.black)
                            .frame(width: 80, height: 80)
                            .background(isRunning ? Color.orange : Color.green)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        isRunning = false
                        timeRemaining = 300
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color(white: 0.2))
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .onReceive(timer) { _ in
            if isRunning && timeRemaining > 0 {
                timeRemaining -= 1
            } else if timeRemaining == 0 {
                isRunning = false
            }
        }
        .navigationTitle("Recovery")
        .navigationBarTitleDisplayMode(.inline)
    }
}
