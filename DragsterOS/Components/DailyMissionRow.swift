import SwiftUI

// 🎨 MISSION: HM Plan Instructions
struct DailyMissionRow: View {
    let task: HMTask
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⚡ DAILY MISSION").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(.green)
                Spacer()
                Text(task.fuelTier).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.gray)
            }
            Text(task.activity).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(task.coachNote).font(.system(size: 14)).italic().foregroundColor(.gray.opacity(0.8))
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading).background(Color(white: 0.05)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}
