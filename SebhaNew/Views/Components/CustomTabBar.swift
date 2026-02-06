import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    onTap: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color.black.opacity(0.8) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    colorScheme == .dark 
                        ? Color.white.opacity(0.1) 
                        : Color.gray.opacity(0.2),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

struct TabBarItem: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .blue : (colorScheme == .dark ? .gray : .secondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
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
        case .sebhas: return "list.bullet.rectangle.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(.home))
        }
        .background(Color.gray.opacity(0.1))
    }
}
