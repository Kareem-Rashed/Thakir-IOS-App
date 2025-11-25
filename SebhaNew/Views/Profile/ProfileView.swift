import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Beautiful gradient background matching HomeView
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.25),
                        Color(red: 0.15, green: 0.25, blue: 0.35),
                        Color(red: 0.2, green: 0.3, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Profile Header
                        //ProfileHeader()
                        
                        // Quick Stats Overview
                       // QuickStatsOverview(viewModel: viewModel)
                        
                        // Achievement Progress
                       // AchievementSection(viewModel: viewModel)
                        
                        // Detailed Statistics
                       // DetailedStatsSection(viewModel: viewModel)
                        
                        // Settings & Actions
                        SettingsSection(viewModel: viewModel)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
            }
        }
    }
}

struct ProfileHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            // Profile Avatar
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text("Digital Sebha User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Spiritual Journey Continues")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.top, 20)
    }
}

struct QuickStatsOverview: View {
    @ObservedObject var viewModel: SebhaViewModel
    
    var totalSebhaCount: Int {
        viewModel.allSebhasCounter.reduce(0, +)
    }
    
    var averagePerSebha: Int {
        guard !viewModel.allSebhasCounter.isEmpty else { return 0 }
        return totalSebhaCount / viewModel.allSebhasCounter.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 15) {
                QuickStatCard(
                    title: "Total Sebhas",
                    value: "\(totalSebhaCount)",
                    icon: "book.fill",
                    color: .green
                )
                
                QuickStatCard(
                    title: "Active Sebhas",
                    value: "\(viewModel.allSebhas.count)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "Average",
                    value: "\(averagePerSebha)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct AchievementSection: View {
    @ObservedObject var viewModel: SebhaViewModel
    
    var achievementLevel: Int {
        let total = viewModel.allSebhasCounter.reduce(0, +)
        switch total {
        case 0..<100: return 1
        case 100..<500: return 2
        case 500..<1000: return 3
        case 1000..<2000: return 4
        default: return 5
        }
    }
    
    var nextMilestone: Int {
        let milestones = [100, 500, 1000, 2000, 5000]
        let total = viewModel.allSebhasCounter.reduce(0, +)
        return milestones.first { $0 > total } ?? 5000
    }
    
    var progressToNext: Double {
        let total = Double(viewModel.allSebhasCounter.reduce(0, +))
        let next = Double(nextMilestone)
        return min(total / next, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Achievement Progress")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Achievement Level
                HStack {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Level \(achievementLevel) Practitioner")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Next milestone: \(nextMilestone) total sebhas")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                // Progress to next level
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress to next level")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(Int(progressToNext * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.yellow, .orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * progressToNext,
                                    height: 8
                                )
                                .animation(.easeInOut(duration: 0.8), value: progressToNext)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

struct DetailedStatsSection: View {
    @ObservedObject var viewModel: SebhaViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Detailed Statistics")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                // Time-based stats
                DetailStatsRow(
                    title: "Today's Progress",
                    value: "\(viewModel.calculateDailyStats())",
                    icon: "calendar",
                    color: .green
                )
                
                DetailStatsRow(
                    title: "This Week",
                    value: "\(viewModel.calculateWeeklyStats())",
                    icon: "calendar.badge.plus",
                    color: .blue
                )
                
                DetailStatsRow(
                    title: "This Month",
                    value: "\(viewModel.calculateMonthlyStats())",
                    icon: "calendar.badge.clock",
                    color: .purple
                )
                
                DetailStatsRow(
                    title: "All Time",
                    value: "\(viewModel.allSebhasCounter.reduce(0, +))",
                    icon: "infinity",
                    color: .orange
                )
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}


struct SettingsSection: View {
    @ObservedObject var viewModel: SebhaViewModel
    @State private var showResetAlert = false
    @State private var showResetDailyAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings & More")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                SettingsButton(
                    title: "Reset Daily Counts",
                    icon: "sunrise",
                    color: .blue
                ) {
                    showResetDailyAlert = true
                }
                
                SettingsButton(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    color: .green
                ) {
                    // Export functionality
                }
                
                SettingsButton(
                    title: "Reset All Statistics",
                    icon: "arrow.counterclockwise",
                    color: .orange
                ) {
                    showResetAlert = true
                }
                
                SettingsButton(
                    title: "Backup & Sync",
                    icon: "icloud",
                    color: .cyan
                ) {
                    // Backup functionality
                }
                
                SettingsButton(
                    title: "About",
                    icon: "info.circle",
                    color: .purple
                ) {
                    // About functionality
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .alert("Reset Daily Counts", isPresented: $showResetDailyAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetAllCurrentCounts()
            }
        } message: {
            Text("This will reset all current session counts to start a new day. Your targets and sebhas will remain unchanged.")
        }
        .alert("Reset All Statistics", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetAllStatistics()
            }
        } message: {
            Text("This will permanently reset all your statistics and count history. This action cannot be undone.")
        }
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    .buttonStyle(PlainButtonStyle())
    }
}

struct DetailStatsRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: SebhaViewModel())
    }
}
