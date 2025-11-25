import Foundation

class SebhaViewModelDelegateClass: SebhaViewModelDelegate {
    var viewModel: SebhaViewModel
    
    init(viewModel: SebhaViewModel) {
        self.viewModel = viewModel
        self.viewModel.delegate = self
    }
    
    func didReachTarget() {
        switchToNextSebha()
    }
    
    private func switchToNextSebha() {
        if let currentIndex = viewModel.allSebhas.firstIndex(of: viewModel.selectedSebha) {
            let nextIndex = (currentIndex + 1) % viewModel.allSebhas.count
            viewModel.selectedSebha = viewModel.allSebhas[nextIndex]
            viewModel.counter = 0
            viewModel.currentTarget = viewModel.allSebhasTarget[nextIndex]
        }
    }
}
