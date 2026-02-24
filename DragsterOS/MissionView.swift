import SwiftUI

struct MissionView: View {
    @StateObject var manager = MissionManager()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // HEADER
                HStack {
                    Text("TODAY's MISSION")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Text(manager.todaysMission.date)
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(.top)
                
                // THE ACTIVITY BLOCK
                VStack(alignment: .leading, spacing: 10) {
                    Text("PRIMARY WORKOUT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Text(manager.todaysMission.activity)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                    
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("TARGET: \(manager.todaysMission.powerTarget)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.15))
                .cornerRadius(12)
                
                // THE FUEL MAP BLOCK
                VStack(alignment: .leading, spacing: 10) {
                    Text("FUEL MAP")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Text(manager.todaysMission.fuel.rawValue)
                        .font(.headline)
                        .foregroundColor(manager.todaysMission.fuel.color)
                    
                    Text("MACROS: \(manager.todaysMission.fuel.macros)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.15))
                .cornerRadius(12)
                
                // COACH'S NOTES
                VStack(alignment: .leading, spacing: 10) {
                    Text("CREW CHIEF NOTES")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Text(manager.todaysMission.coachNotes)
                        .font(.body)
                        .foregroundColor(.orange)
                        .italic()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.15))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle("Whiteboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}
