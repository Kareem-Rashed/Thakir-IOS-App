import Foundation
import SwiftUI


// MARK: - Date Extensions
extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func isSameDay(as date: Date) -> Bool {
        return Calendar.current.isDate(self, inSameDayAs: date)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.blue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Color Extensions
extension Color {
    static let sebhaBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let sebhaGreen = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let sebhaOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    static func adaptiveBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8)
    }
}

// MARK: - Haptic Feedback
struct HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
