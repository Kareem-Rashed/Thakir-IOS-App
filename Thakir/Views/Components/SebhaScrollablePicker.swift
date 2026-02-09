import SwiftUI

struct SebhaScrollablePicker: View {
    @Binding var selectedSebha: String
    @Binding var counterUpdate: Int
    @Binding var targetUpdate: Int
    var allSebhas: [String]
    var allSebhasTarget: [Int]
    var onSebhaSelected: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(allSebhas.indices, id: \.self) { index in
                        SebhaPickerItem(
                            sebha: allSebhas[index],
                            isSelected: index == (allSebhas.firstIndex(of: selectedSebha) ?? 0),
                            onTap: {
                                withAnimation(.spring(response: 0.4)) {
                                    proxy.scrollTo(index, anchor: .center)
                                    onSebhaSelected(index)
                                }
                            }
                        )
                        .id(index)
                    }
                }
                .padding(.vertical, 16)
            }
            .frame(height: 180)
            .onChange(of: selectedSebha) { newValue in
                if let index = allSebhas.firstIndex(of: newValue) {
                    withAnimation(.spring(response: 0.4)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
    }
}

struct SebhaPickerItem: View {
    let sebha: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(sebha)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .shadow(
                    color: isSelected ? Color.white.opacity(0.2) : Color.clear,
                    radius: isSelected ? 8 : 0,
                    x: 0,
                    y: isSelected ? 4 : 0
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct SebhaScrollablePicker_Previews: PreviewProvider {
    static var previews: some View {
        SebhaScrollablePicker(
            selectedSebha: .constant("سبحان الله"),
            counterUpdate: .constant(5),
            targetUpdate: .constant(10),
            allSebhas: ["سبحان الله", "الحمد لله", "لا اله الا الله"],
            allSebhasTarget: [10, 20, 30],
            onSebhaSelected: { _ in }
        )
        .preferredColorScheme(.dark)
        .frame(height: 200)
    }
}
