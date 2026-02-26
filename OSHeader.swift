import SwiftUI

struct OSHeader: View {
    var title: String
    var systemState: String
    var stateValue: String
    var showBackButton: Bool = false
    var backAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                
                // ✨ INTEGRATED BACK BUTTON
                if showBackButton {
                    Button(action: { backAction?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(ColorTheme.prime)
                            .frame(width: 32, height: 32)
                            .background(ColorTheme.surface)
                            .clipShape(Circle())
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("DRAGSTER OS // V3.1-FLASH")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime.opacity(0.8))
                    
                    Text(title.uppercased())
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(systemState.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                    
                    Text(stateValue.uppercased())
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(ColorTheme.background.opacity(0.9))
            
            Divider().background(ColorTheme.prime.opacity(0.3))
        }
    }
}
