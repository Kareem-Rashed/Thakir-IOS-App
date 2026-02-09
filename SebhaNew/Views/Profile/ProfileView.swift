import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: SebhaViewModel
    @EnvironmentObject var appLanguage: AppLanguage
    @State private var showResetAlert = false
    @State private var showResetAllAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background matching HomeView
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.25),
                        Color(red: 0.2, green: 0.3, blue: 0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.top, 20)
                            
                            Text(appLanguage.string(for: .statistics))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Track your spiritual progress")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.bottom, 10)
                        
                        // Settings Card - NEW
                        VStack(spacing: 16) {
                            Text(appLanguage.string(for: .settings))
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: appLanguage.currentLanguage.isRTL ? .trailing : .leading)
                            
                            // Language Picker
                            HStack {
                                Label(appLanguage.string(for: .language), systemImage: "globe")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Picker("", selection: $appLanguage.currentLanguage) {
                                    ForEach(AppLanguage.Language.allCases, id: \.self) { language in
                                        Text(language.displayName).tag(language)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.blue)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // Quick Summary Card
                        VStack(spacing: 16) {
                            Text("Total Progress")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 20) {
                                StatBox(
                                    title: "All Time",
                                    value: "\(viewModel.allTimeTotal)",
                                    icon: "infinity",
                                    color: .purple
                                )
                                
                                StatBox(
                                    title: "Today",
                                    value: "\(viewModel.todayTotal)",
                                    icon: "calendar",
                                    color: .green
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // Per-Sebha Statistics
                        VStack(spacing: 16) {
                            HStack {
                                Text("Sebha Details")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Text("\(viewModel.allSebhas.count) Sebhas")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            ForEach(viewModel.allSebhas.indices, id: \.self) { index in
                                SebhaStatRow(
                                    name: viewModel.allSebhas[index],
                                    count: viewModel.allSebhasCounter[index],
                                    target: viewModel.allSebhasTarget[index]
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // Reset Actions
                        VStack(spacing: 12) {
                            Text("Reset Options")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Reset All Counters
                            Button(action: { showResetAlert = true }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                    
                                    Text("Reset All Counters")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Reset All Statistics
                            Button(action: { showResetAllAlert = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                    
                                    Text("Reset All Statistics")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("Reset counters to start a new session. Statistics will be permanently deleted.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        
                        // Bottom padding for tab bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
        }
        .alert("Reset All Counters?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetAllCurrentCounts()
            }
        } message: {
            Text("This will reset all current counters to 0. History will be preserved.")
        }
        .alert("Reset All Statistics?", isPresented: $showResetAllAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                viewModel.resetAllStatistics()
            }
        } message: {
            Text("This will permanently delete all statistics and history. This cannot be undone.")
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SebhaStatRow: View {
    let name: String
    let count: Int
    let target: Int
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(count) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(count)/\(target)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(progress >= 1.0 ? .green : .white.opacity(0.8))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: SebhaViewModel())
            .preferredColorScheme(.dark)
    }
}
