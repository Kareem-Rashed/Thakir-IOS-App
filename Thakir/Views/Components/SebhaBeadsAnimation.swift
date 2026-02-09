import SwiftUI

/// A beautiful animated sebha (prayer beads) visualization
struct SebhaBeadsAnimation: View {
    let progress: Double // 0.0 to 1.0
    let beadCount: Int = 33 // Traditional sebha has 33 or 99 beads
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            SebhaBeadsContent(
                progress: progress,
                beadCount: beadCount,
                rotationAngle: rotationAngle,
                geometry: geometry
            )
        }
        .onAppear {
            // Slow rotation animation
            withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                rotationAngle = 2 * .pi
            }
        }
    }
}

// Separate content view to simplify type checking
struct SebhaBeadsContent: View {
    let progress: Double
    let beadCount: Int
    let rotationAngle: Double
    let geometry: GeometryProxy
    
    private var minDimension: CGFloat {
        min(geometry.size.width, geometry.size.height)
    }
    
    private var radius: CGFloat {
        minDimension / 2.5
    }
    
    private var center: CGPoint {
        CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
    
    var body: some View {
        ZStack {
            // Sebha string/thread
            sebhaRing
            
            // Prayer beads
            beadsLayer
            
            // Center tassel
            TasselView()
                .offset(y: radius + 30)
        }
    }
    
    private var sebhaRing: some View {
        Circle()
            .stroke(ringGradient, lineWidth: 2)
            .frame(width: radius * 2, height: radius * 2)
    }
    
    private var ringGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.3),
                Color.white.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var beadsLayer: some View {
        ForEach(0..<beadCount, id: \.self) { index in
            beadView(at: index)
        }
    }
    
    private func beadView(at index: Int) -> some View {
        let angle = calculateAngle(for: index)
        let position = calculatePosition(angle: angle)
        let beadProgress = Double(index) / Double(beadCount)
        let isActivated = beadProgress <= progress
        
        return BeadView(
            isActivated: isActivated,
            isDivider: index % 11 == 0
        )
        .position(x: position.x, y: position.y)
    }
    
    private func calculateAngle(for index: Int) -> Double {
        (Double(index) / Double(beadCount)) * 2 * .pi - .pi / 2 + rotationAngle
    }
    
    private func calculatePosition(angle: Double) -> CGPoint {
        let x = center.x + radius * CGFloat(cos(angle))
        let y = center.y + radius * CGFloat(sin(angle))
        return CGPoint(x: x, y: y)
    }
}

struct BeadView: View {
    let isActivated: Bool
    let isDivider: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Bead shadow
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: isDivider ? 14 : 10, height: isDivider ? 14 : 10)
                .blur(radius: 3)
                .offset(y: 2)
            
            // Main bead
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            isActivated ? Color.yellow : Color.white.opacity(0.3),
                            isActivated ? Color.orange : Color.white.opacity(0.15)
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: isDivider ? 12 : 8
                    )
                )
                .frame(width: isDivider ? 12 : 8, height: isDivider ? 12 : 8)
                .overlay(
                    Circle()
                        .stroke(
                            isActivated ? Color.white.opacity(0.5) : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .scaleEffect(pulseScale)
                .shadow(
                    color: isActivated ? Color.yellow.opacity(0.6) : Color.clear,
                    radius: isActivated ? 4 : 0
                )
        }
        .onChange(of: isActivated) { newValue in
            if newValue {
                // Pulse animation when bead activates
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    pulseScale = 1.3
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                    pulseScale = 1.0
                }
            }
        }
    }
}

struct TasselView: View {
    @State private var swingAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tassel connector bead
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
            
            // Tassel strings
            VStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.yellow.opacity(0.8),
                                    Color.orange.opacity(0.6)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: CGFloat(15 - index * 2))
                        .offset(x: CGFloat(index - 2) * 3)
                }
            }
        }
        .rotationEffect(.degrees(swingAngle))
        .onAppear {
            // Gentle swing animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                swingAngle = 3
            }
        }
    }
}

// Simplified version for smaller spaces
struct MiniSebhaBeadsAnimation: View {
    let progress: Double
    let beadCount: Int = 12 // Fewer beads for mini version
    
    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2.2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // Ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    .frame(width: radius * 2, height: radius * 2)
                
                // Beads
                ForEach(0..<beadCount, id: \.self) { index in
                    let angle = (Double(index) / Double(beadCount)) * 2 * .pi - .pi / 2
                    let x = center.x + radius * CGFloat(cos(angle))
                    let y = center.y + radius * CGFloat(sin(angle))
                    
                    let beadProgress = Double(index) / Double(beadCount)
                    let isActivated = beadProgress <= progress
                    
                    Circle()
                        .fill(isActivated ? Color.yellow : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .shadow(
                            color: isActivated ? Color.yellow.opacity(0.6) : Color.clear,
                            radius: isActivated ? 3 : 0
                        )
                        .position(x: x, y: y)
                }
            }
        }
    }
}

struct SebhaBeadsAnimation_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack(spacing: 40) {
                SebhaBeadsAnimation(progress: 0.75)
                    .frame(width: 300, height: 300)
                
                MiniSebhaBeadsAnimation(progress: 0.5)
                    .frame(width: 150, height: 150)
            }
        }
        .ignoresSafeArea()
    }
}
