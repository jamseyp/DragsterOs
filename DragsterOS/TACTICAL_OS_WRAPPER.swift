import SwiftUI
import SwiftData

struct TacticalOSWrapper: ViewModifier {
    var title: String
    var showBack: Bool
    
    // ✨ Global dismiss capability
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TelemetryLog.date, order: .reverse) private var logs: [TelemetryLog]
    
    private var liveReadiness: String {
        if let latest = logs.first {
            return "READINESS: \(Int(latest.readinessScore))%"
        }
        return "READINESS: --%"
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            ColorTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ✨ HEADER NOW RECEIVES THE BACK LOGIC
                OSHeader(
                    title: title,
                    systemState: "LIVE BIOMETRIC FEED",
                    stateValue: liveReadiness,
                    showBackButton: showBack,
                    backAction: { dismiss() }
                )
                
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
    }
}

extension View {
    // Default showBack to true, since most screens are sub-screens
    func applyTacticalOS(title: String, showBack: Bool = true) -> some View {
        self.modifier(TacticalOSWrapper(title: title, showBack: showBack))
    }
}
