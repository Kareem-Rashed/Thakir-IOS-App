// filepath: /Users/kareem/Apps/SebhaNew/SebhaNew/Views/Home/HomeViewImproved.swift
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var buttonScale: CGFloat = 1.0
    @State private var showSebhaSheet = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark 
                        ? Color(red: 0.05, green: 0.05, blue: 0.1)
                        : Color(red: 0.95, green: 0.96, blue: 0.98),
                    colorScheme == .dark
                        ? Color(red: 0.1, green: 0.1, blue: 0.15)
                        : Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Compact Header with Logo
                HStack {
                    Image(colorScheme == .dark ? "darkLogo" : "lightLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                    
                    Spacer()
                    
                    // Voice toggle
                    SimpleVoiceToggle(viewModel: viewModel)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Sebha Selector Card
                        VStack(spacing: 16) {
                            Button(action: { showSebhaSheet = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Current Sebha")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.secondary)
                                        
                                        Text(viewModel.selectedSebha)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Main Counter Circle
                        MainCounterCircle(viewModel: viewModel, buttonScale: $buttonScale)
                            .padding(.horizontal, 20)
                        
                        // Stats Row
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Target",
                                value: "\(viewModel.currentTarget)",
                                icon: "target",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Progress",
                                value: "\(Int(viewModel.currentSebhaProgress * 100))%",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Today",
                                value: "\(viewModel.todayTotal)",
                                icon: "calendar",
                                color: .orange
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .sheet(isPresented: $showSebhaSheet) {
            SebhaSelectionSheet(viewModel: viewModel, isPresented: $showSebhaSheet)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}

struct MainCounterCircle: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var buttonScale: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Progress ring
                Circle()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.2),
                        lineWidth: 12
                    )
                    .frame(width: 240, height: 240)
                
                Circle()
                    .trim(from: 0, to: viewModel.currentSebhaProgress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentSebhaProgress)
                
                // Counter button
                Button(action: {
                    viewModel.incrementCount(for: viewModel.selectedSebha)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        buttonScale = 0.95
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            buttonScale = 1.0
                        }
                    }
                }) {
                    VStack(spacing: 8) {
                        Text("\(viewModel.counter)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Tap to count")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 200, height: 200)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(buttonScale)
            }
            
            // Reset button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    viewModel.allSebhasCounter[viewModel.currentIndex] = 0
                    viewModel.counter = 0
                    viewModel.updateProgress()
                    viewModel.saveSebhas()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Reset")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
    }
}

struct SimpleVoiceToggle: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.isVoice.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isVoice ? "mic.fill" : "mic.slash.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.isVoice ? .white : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(viewModel.isVoice ? Color.blue : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SebhaSelectionSheet: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.allSebhas.indices, id: \.self) { index in
                        Button(action: {
                            viewModel.selectSebha(at: index)
                            isPresented = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.allSebhas[index])
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("\(viewModel.allSebhasCounter[index]) / \(viewModel.allSebhasTarget[index])")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if viewModel.currentIndex == index {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(colorScheme == .dark ? Color.black : Color(red: 0.95, green: 0.96, blue: 0.98))
            .navigationTitle("Select Sebha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: SebhaViewModel())
    }
}
