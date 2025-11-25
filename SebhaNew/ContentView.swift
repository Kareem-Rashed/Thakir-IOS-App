import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SebhaViewModel()
    @State private var delegate: SebhaViewModelDelegateClass?
    @State private var selectedTab: Tab = .home
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Beautiful gradient background matching the app theme
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

                VStack(spacing: 0) {
                    // Main Content
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeView(viewModel: viewModel)
                        case .sebhas:
                            SebhasView(viewModel: viewModel)
                        case .profile:
                            ProfileView(viewModel: viewModel)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Custom Tab Bar
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("🎉 Congratulations!"),
                message: Text("You have completed your target of \(viewModel.currentTarget) for \(viewModel.selectedSebha)!"),
                dismissButton: .default(Text("Continue")) {
                    // Alert dismissed, auto-switching handled in ViewModel
                }
            )
        }
        .onAppear {
            delegate = SebhaViewModelDelegateClass(viewModel: viewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
