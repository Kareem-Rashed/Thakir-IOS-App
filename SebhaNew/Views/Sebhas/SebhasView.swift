import SwiftUI

struct SebhasView: View {
    @ObservedObject var viewModel: SebhaViewModel
    @State private var showAddSebhaSheet = false
    @State private var showEditSebhaSheet = false
    @State private var showRecordVoiceSheet = false
    @State private var recordingVoiceForIndex: Int? = nil
    @State private var editingSebhaIndex: Int?
    @State private var newSebhaName = ""
    @State private var newSebhaTarget = ""
    @State private var editMode: EditMode = .inactive

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
                
                VStack(spacing: 0) {
                    // Enhanced Header
                    SebhasHeaderView(editMode: $editMode)
                    
                    // Direct List without ScrollView wrapper to prevent nesting issues
                    VStack(spacing: 0) {
                        // Sebhas List with drag and drop
                        List {
                            ForEach(viewModel.allSebhas.indices, id: \.self) { index in
                                ModernSebhaCard(
                                    sebha: viewModel.allSebhas[index],
                                    target: viewModel.allSebhasTarget[index],
                                    count: viewModel.allSebhasCounter[index],
                                    isSelected: viewModel.selectedSebha == viewModel.allSebhas[index],
                                    editMode: editMode,
                                    onTap: {
                                        if editMode == .inactive {
                                            viewModel.selectSebha(at: index)
                                        }
                                    },
                                    onEdit: {
                                        editingSebhaIndex = index
                                        viewModel.editSebhaTarget(at: index)
                                        showEditSebhaSheet = true
                                    },
                                    onRecordVoice: {
                                        recordingVoiceForIndex = index
                                        showRecordVoiceSheet = true
                                    },
                                    viewModel: viewModel
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            }
                            .onMove(perform: editMode == .active ? moveSebha : nil)
                            .onDelete(perform: editMode == .active ? deleteSebha : nil)
                            
                            // Add Button as last row
                            AddSebhaButton {
                                showAddSebhaSheet = true
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 40, trailing: 20))
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .environment(\.editMode, $editMode)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSebhaSheet) {
            AddSebhaSheetNew(viewModel: viewModel, isPresented: $showAddSebhaSheet, newSebhaTarget: $newSebhaTarget)
        }
        .sheet(isPresented: $showEditSebhaSheet) {
            EditSebhaSheetNew(viewModel: viewModel, isPresented: $showEditSebhaSheet)
        }
        .sheet(isPresented: $showRecordVoiceSheet) {
            RecordVoiceSheet(
                viewModel: viewModel,
                isPresented: $showRecordVoiceSheet,
                sebhaIndex: recordingVoiceForIndex ?? 0
            )
        }
    }
    
    // MARK: - Helper Functions
    private func moveSebha(from source: IndexSet, to destination: Int) {
        viewModel.moveSebha(from: source, to: destination)
    }
    
    private func deleteSebha(at offsets: IndexSet) {
        offsets.forEach { viewModel.removeSebha(at: $0) }
    }
}

struct SebhasHeaderView: View {
    @Binding var editMode: EditMode
    
    var body: some View {
        HStack {
            Text("My Sebhas")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    editMode = editMode == .active ? .inactive : .active
                }
            }) {
                Text(editMode == .active ? "Done" : "Edit")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
}

struct ModernSebhaCard: View {
    let sebha: String
    let target: Int
    let count: Int
    let isSelected: Bool
    let editMode: EditMode
    let onTap: () -> Void
    let onEdit: () -> Void
    let onRecordVoice: () -> Void
    @ObservedObject var viewModel: SebhaViewModel
    
    var completionPercentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(count) / Double(target), 1.0)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Drag handle for edit mode
                    if editMode == .active {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Sebha Text and Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sebha)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(count)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Target")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(target)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Progress")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(Int(completionPercentage * 100))%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(completionPercentage >= 1.0 ? .yellow : .purple)
                            }
                        }
                        
                        // Action buttons for normal mode
                        if editMode == .inactive {
                            HStack(spacing: 12) {
                                // Record voice button
                                Button(action: onRecordVoice) {
                                    Image(systemName: "waveform.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Voice recording status
                                Button(action: {
                                    if viewModel.hasVoiceRecording(for: sebha) {
                                        viewModel.playVoicePrompt(for: sebha)
                                    }
                                }) {
                                    Image(systemName: viewModel.hasVoiceRecording(for: sebha) ? "play.circle.fill" : "mic.slash.circle")
                                        .font(.title3)
                                        .foregroundColor(viewModel.hasVoiceRecording(for: sebha) ? .green : .gray.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: onEdit) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator or circular progress
                    if isSelected && editMode == .inactive {
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 3)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .trim(from: 0, to: completionPercentage)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.green, .blue, .purple]),
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.8), value: completionPercentage)
                            
                            Image(systemName: "checkmark")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? .ultraThinMaterial : .thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? .white.opacity(0.4) : .white.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isSelected ? .white.opacity(0.2) : .black.opacity(0.3),
            radius: isSelected ? 15 : 10,
            x: 0,
            y: isSelected ? 8 : 5
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddSebhaButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Add New Sebha")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - Add Sebha Sheet
struct AddSebhaSheetNew: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var isPresented: Bool
    @Binding var newSebhaTarget: String
    
    var body: some View {
        NavigationView {
            ZStack {
                // Matching gradient background
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
                
                VStack(spacing: 24) {
                    Text("Add New Sebha")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sebha Text")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("Enter sebha text", text: $viewModel.recognizedText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Daily Target")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("Enter daily target", text: $newSebhaTarget)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .font(.body)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            resetFields()
                            isPresented = false
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button("Add Sebha") {
                            if let target = Int(newSebhaTarget), !viewModel.recognizedText.isEmpty {
                                viewModel.newSebha = viewModel.recognizedText
                                viewModel.newSebhaTarget = newSebhaTarget
                                viewModel.addCustomSebha()
                                resetFields()
                                isPresented = false
                            }
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(canAddSebha ? Color.green : Color.gray)
                        .cornerRadius(12)
                        .disabled(!canAddSebha)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var canAddSebha: Bool {
        !viewModel.recognizedText.isEmpty && !newSebhaTarget.isEmpty && Int(newSebhaTarget) != nil
    }
    
    private func resetFields() {
        viewModel.recognizedText = ""
        newSebhaTarget = ""
    }
}

// MARK: - Edit Sebha Sheet
struct EditSebhaSheetNew: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Matching gradient background
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
                
                VStack(spacing: 24) {
                    Text("Edit Target")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New Daily Target")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        TextField("Enter new target", text: $viewModel.newTarget)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button("Save") {
                            viewModel.updateSebhaTarget()
                            isPresented = false
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(canSave ? Color.green : Color.gray)
                        .cornerRadius(12)
                        .disabled(!canSave)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var canSave: Bool {
        !viewModel.newTarget.isEmpty && Int(viewModel.newTarget) != nil
    }
}

// MARK: - Record Voice Sheet
struct RecordVoiceSheet: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var isPresented: Bool
    let sebhaIndex: Int
    
    private var sebha: String {
        guard sebhaIndex < viewModel.allSebhas.count else { return "" }
        return viewModel.allSebhas[sebhaIndex]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Matching gradient background
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
                
                VStack(spacing: 30) {
                    Text("Record Voice Prompt")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        Text("Sebha:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(sebha)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(spacing: 20) {
                        Text("Record yourself saying this sebha. This will be played when you switch to this sebha.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Recording button
                        Button(action: {
                            if viewModel.isRecordingVoicePrompt {
                                viewModel.stopRecordingVoicePrompt()
                            } else {
                                viewModel.startRecordingVoicePrompt(for: sebha)
                            }
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: viewModel.isRecordingVoicePrompt ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                
                                Text(viewModel.isRecordingVoicePrompt ? "Stop Recording" : "Start Recording")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 30)
                            .padding(.horizontal, 40)
                            .background(viewModel.isRecordingVoicePrompt ? Color.red : Color.blue)
                            .cornerRadius(20)
                            .shadow(color: viewModel.isRecordingVoicePrompt ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        // Play and Delete buttons (if recording exists)
                        if viewModel.hasVoiceRecording(for: sebha) {
                            HStack(spacing: 16) {
                                Button(action: {
                                    viewModel.playVoicePrompt(for: sebha)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                        Text("Play")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.green)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    viewModel.deleteVoiceRecording(for: sebha)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash.circle.fill")
                                            .font(.title2)
                                        Text("Delete")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.red)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Done button
                    Button("Done") {
                        if viewModel.isRecordingVoicePrompt {
                            viewModel.stopRecordingVoicePrompt()
                        }
                        isPresented = false
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 40)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct SebhasView_Previews: PreviewProvider {
    static var previews: some View {
        SebhasView(viewModel: SebhaViewModel())
            .preferredColorScheme(.dark)
    }
}
