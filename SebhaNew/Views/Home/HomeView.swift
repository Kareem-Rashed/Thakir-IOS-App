import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var buttonScale: CGFloat = 1.0
    @State private var showSebhaDropdown = false
    
    var progress: Double {
        guard viewModel.currentTarget > 0 else { return 0 }
        return min(Double(viewModel.counter) / Double(viewModel.currentTarget), 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simple background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.25),
                        Color(red: 0.2, green: 0.3, blue: 0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 60) {
                    // App Logo from Assets
                    AppLogo()
                    
                    
                    // Main Counter Circle with dropdown arrow
                    HStack(spacing: 20) {
                        // Big pressable circle
                        MainCounterCircle(
                            viewModel: viewModel,
                            progress: progress,
                            buttonScale: $buttonScale,
                            geometry: geometry
                        )
                        
                        // Small dropdown arrow
                        DropdownButton(
                            viewModel: viewModel,
                            showDropdown: $showSebhaDropdown
                        )
                    }
                    
                    Spacer()
                    
                    // Voice toggle button
                    SimpleVoiceToggle(viewModel: viewModel)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
        }
        .sheet(isPresented: $showSebhaDropdown) {
            SebhaSelectionSheet(viewModel: viewModel, isPresented: $showSebhaDropdown)
        }
    }
}

struct AppLogo: View {
    var body: some View {
        VStack(spacing: 0) {
            // Try to load from assets, fallback to text
            if let logo = UIImage(named: "lightLogo") {
                Image(uiImage: logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 180)
            } else {
                // Fallback logo
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text("سبحة")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct MainCounterCircle: View {
    @ObservedObject var viewModel: SebhaViewModel
    let progress: Double
    @Binding var buttonScale: CGFloat
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                buttonScale = 0.95
                viewModel.incrementCount(for: viewModel.selectedSebha)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 1.0
                }
            }
        }) {
            ZStack {
                // Progress ring background
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 8)
                    .frame(width: min(geometry.size.width * 0.6, 250))
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: min(geometry.size.width * 0.6, 250))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: progress)
                
                // Counter content
                VStack(spacing: 12) {
                    Text("\(viewModel.counter)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    
                    Text(viewModel.selectedSebha)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("\(viewModel.counter)/\(viewModel.currentTarget)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: min(geometry.size.width * 0.5, 200), height: min(geometry.size.width * 0.5, 200))
                .background(
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 100
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            }
        }
        .scaleEffect(buttonScale)
        .buttonStyle(PlainButtonStyle())
    }
}

struct DropdownButton: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var showDropdown: Bool
    
    var body: some View {
        Button(action: {
            showDropdown.toggle()
        }) {
            Image(systemName: "chevron.down.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SimpleVoiceToggle: View {
    @ObservedObject var viewModel: SebhaViewModel
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                viewModel.isVoice.toggle()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isVoice ? "mic.fill" : "mic.slash.fill")
                    .font(.title3)
                    .foregroundColor(viewModel.isVoice ? .green : .white.opacity(0.6))
                
                Text(viewModel.isVoice ? "Voice On" : "Voice Off")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Simple toggle
                RoundedRectangle(cornerRadius: 15)
                    .fill(viewModel.isVoice ? .green : .gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 24, height: 24)
                            .offset(x: viewModel.isVoice ? 10 : -10)
                            .animation(.spring(response: 0.3), value: viewModel.isVoice)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SebhaSelectionSheet: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.25),
                        Color(red: 0.2, green: 0.3, blue: 0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.allSebhas.indices, id: \.self) { index in
                            Button(action: {
                                viewModel.selectSebha(at: index)
                                isPresented = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(viewModel.allSebhas[index])
                                            .font(.title3)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Text("Target: \(viewModel.allSebhasTarget[index]) | Count: \(viewModel.allSebhasCounter[index])")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedSebha == viewModel.allSebhas[index] {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Sebha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: SebhaViewModel())
            .preferredColorScheme(.dark)
    }
}
