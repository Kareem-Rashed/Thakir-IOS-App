import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SebhaViewModel()
    @State private var delegate: SebhaViewModelDelegateClass?
    @State private var selectedTab: Tab = .home
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
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
            
            // Compact floating tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
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
