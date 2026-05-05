import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default:(a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }

    static let appBG = Color(hex: "0D0D1A")
    static let cardBG = Color(hex: "1A1A2E")
    static let cardBG2 = Color(hex: "16213E")
    static let accentPurple = Color(hex: "7B2FBE")
    static let accentBlue = Color(hex: "4361EE")
    static let focusGreen = Color(hex: "00C853")
    static let strugglingOrange = Color(hex: "FF6D00")
    static let drowsyPurple = Color(hex: "AA00FF")
    static let awayRed = Color(hex: "FF1744")
}

extension EmotionState {
    var swiftColor: Color {
        switch self {
        case .focused: return .focusGreen
        case .drowsy: return .drowsyPurple
        case .away: return .awayRed
        }
    }
}

struct GlassCard: ViewModifier {
    var color: Color = Color.white.opacity(0.06)
    func body(content: Content) -> some View {
        content
            .background(color)
            .cornerRadius(18)
    }
}

extension View {
    func glassCard(color: Color = Color.white.opacity(0.06)) -> some View {
        modifier(GlassCard(color: color))
    }
}
