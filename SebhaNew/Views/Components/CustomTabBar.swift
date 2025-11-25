import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -10)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 34) // Better safe area padding
    }
}

struct TabBarItem: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .frame(height: 20)
                
                Text(tab.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .white.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .white.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

enum Tab: CaseIterable {
    case home, sebhas, profile
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .sebhas: return "Sebhas" 
        case .profile: return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .sebhas: return "book.fill"
        case .profile: return "person.fill"
        }
    }
}

struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabBar(selectedTab: .constant(.home))
            .preferredColorScheme(.dark)
    }
}
