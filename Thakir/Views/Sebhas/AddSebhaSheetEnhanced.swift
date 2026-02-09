import SwiftUI
import Speech

struct AddSebhaSheetEnhanced: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var isPresented: Bool
    @EnvironmentObject var appLanguage: AppLanguage
    
    @State private var sebhaText = ""
    @State private var targetCount = ""
    @State private var isRecordingText = false
    @State private var isRecordingVoice = false
    @State private var showSuccessAnimation = false
    @State private var validationError: String?
    
    // Input method tracking
    @State private var inputMethod: InputMethod = .text
    
    enum InputMethod {
        case text
        case voice
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
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
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 8) {
                            Text(appLanguage.string(for: .addNewSebha))
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(appLanguage.string(for: .createSebhaDesc))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        // Input Method Selector
                        InputMethodPicker(selectedMethod: $inputMethod)
                        
                        // Sebha Text Section
                        VStack(spacing: 16) {
                            SectionHeader(
                                icon: "text.bubble.fill",
                                title: appLanguage.string(for: .sebhaText),
                                subtitle: inputMethod == .voice ? appLanguage.string(for: .tapMicToSpeak) : appLanguage.string(for: .typeYourSebha)
                            )
                            
                            if inputMethod == .text {
                                // Text Input
                                ModernTextField(
                                    placeholder: appLanguage.string(for: .example),
                                    text: $sebhaText,
                                    icon: "text.alignleft"
                                )
                            } else {
                                // Voice Input
                                VoiceInputCard(
                                    text: $sebhaText,
                                    isRecording: $isRecordingText,
                                    onRecord: {
                                        toggleTextRecording()
                                    }
                                )
                            }
                            
                            // Display recognized text if any
                            if !sebhaText.isEmpty {
                                RecognizedTextDisplay(text: sebhaText)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Target Count Section
                        VStack(spacing: 16) {
                            SectionHeader(
                                icon: "target",
                                title: appLanguage.string(for: .dailyTarget),
                                subtitle: appLanguage.string(for: .howManyTimes)
                            )
                            
                            TargetCountSelector(targetCount: $targetCount)
                        }
                        .padding(.horizontal, 20)
                        
                        // Voice Prompt Section (Optional)
                        VStack(spacing: 16) {
                            SectionHeader(
                                icon: "waveform.circle.fill",
                                title: "\(appLanguage.string(for: .voicePrompt)) (\(appLanguage.string(for: .optional)))",
                                subtitle: appLanguage.string(for: .recordPronunciation)
                            )
                            
                            VoicePromptRecorder(
                                sebhaText: sebhaText,
                                isRecording: $isRecordingVoice,
                                viewModel: viewModel
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Validation Error
                        if let error = validationError {
                            ValidationErrorView(message: error)
                                .padding(.horizontal, 20)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                resetFields()
                                isPresented = false
                            }) {
                                ActionButton(
                                    title: appLanguage.string(for: .cancel),
                                    icon: "xmark.circle.fill",
                                    color: .red,
                                    style: .secondary
                                )
                            }
                            
                            Button(action: {
                                addSebha()
                            }) {
                                ActionButton(
                                    title: appLanguage.string(for: .addSebha),
                                    icon: "plus.circle.fill",
                                    color: .green,
                                    style: .primary
                                )
                            }
                            .disabled(!canAddSebha)
                            .opacity(canAddSebha ? 1.0 : 0.5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
                
                // Success Animation Overlay
                if showSuccessAnimation {
                    SuccessAnimationView()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
        }
        .onDisappear {
            // Clean up any active recordings
            if isRecordingText {
                viewModel.stopSpeechRecognitionForNewSebha()
            }
            if isRecordingVoice {
                viewModel.stopRecordingVoicePrompt()
            }
        }
    }
    
    // MARK: - Helper Properties
    private var canAddSebha: Bool {
        !sebhaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !targetCount.isEmpty &&
        Int(targetCount) != nil &&
        (Int(targetCount) ?? 0) > 0
    }
    
    // MARK: - Actions
    private func toggleTextRecording() {
        if isRecordingText {
            viewModel.stopSpeechRecognitionForNewSebha()
            isRecordingText = false
        } else {
            // Request permission first
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        viewModel.recognizedText = ""
                        viewModel.startSpeechRecognitionForNewSebha()
                        isRecordingText = true
                        
                        // Bind viewModel's recognized text to our local state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.updateSebhaText()
                        }
                    } else {
                        validationError = "Speech recognition permission denied"
                    }
                }
            }
        }
    }
    
    private func updateSebhaText() {
        if isRecordingText {
            sebhaText = viewModel.recognizedText
            // Continue updating
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateSebhaText()
            }
        }
    }
    
    private func addSebha() {
        // Validate
        guard canAddSebha else {
            validationError = "Please fill in all required fields"
            return
        }
        
        guard let target = Int(targetCount), target > 0, target <= 10000 else {
            validationError = "Target must be between 1 and 10,000"
            return
        }
        
        // Add the sebha
        viewModel.newSebha = sebhaText.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.newSebhaTarget = targetCount
        viewModel.addCustomSebha()
        
        // Show success animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showSuccessAnimation = true
        }
        
        // Dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            resetFields()
            isPresented = false
        }
    }
    
    private func resetFields() {
        sebhaText = ""
        targetCount = ""
        validationError = nil
        viewModel.recognizedText = ""
        
        if isRecordingText {
            viewModel.stopSpeechRecognitionForNewSebha()
            isRecordingText = false
        }
        if isRecordingVoice {
            viewModel.stopRecordingVoicePrompt()
            isRecordingVoice = false
        }
    }
}

// MARK: - Input Method Picker
struct InputMethodPicker: View {
    @Binding var selectedMethod: AddSebhaSheetEnhanced.InputMethod
    @EnvironmentObject var appLanguage: AppLanguage
    
    var body: some View {
        HStack(spacing: 12) {
            MethodButton(
                icon: "keyboard",
                title: appLanguage.string(for: .typeText),
                isSelected: selectedMethod == .text,
                action: { selectedMethod = .text }
            )
            
            MethodButton(
                icon: "mic.fill",
                title: appLanguage.string(for: .voiceInput),
                isSelected: selectedMethod == .voice,
                action: { selectedMethod = .voice }
            )
        }
        .padding(.horizontal, 20)
    }
}

struct MethodButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 2)
            )
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
}

// MARK: - Modern Text Field
struct ModernTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.6))
            
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(.white)
                .accentColor(.blue)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Voice Input Card
struct VoiceInputCard: View {
    @Binding var text: String
    @Binding var isRecording: Bool
    let onRecord: () -> Void
    
    var body: some View {
        Button(action: onRecord) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                        .frame(width: 50, height: 50)
                    
                    if isRecording {
                        Circle()
                            .fill(Color.red.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .scaleEffect(1.5)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                value: isRecording
                            )
                    }
                    
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isRecording ? "Recording..." : "Tap to speak")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(isRecording ? "Listening to your voice" : "Say your sebha phrase")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if isRecording {
                    WaveformAnimation()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isRecording ? Color.red : Color.blue, lineWidth: 2)
            )
        }
    }
}

// MARK: - Waveform Animation
struct WaveformAnimation: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 3, height: animating ? CGFloat.random(in: 10...25) : 10)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Recognized Text Display
struct RecognizedTextDisplay: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Recognized:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(text)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - Target Count Selector
struct TargetCountSelector: View {
    @Binding var targetCount: String
    
    let quickOptions = ["33", "66", "99", "100", "300", "500", "1000"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Quick selection buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickOptions, id: \.self) { option in
                        QuickTargetButton(
                            value: option,
                            isSelected: targetCount == option,
                            action: { targetCount = option }
                        )
                    }
                }
            }
            
            // Custom input
            HStack(spacing: 12) {
                Image(systemName: "number")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Custom target", text: $targetCount)
                    .font(.body)
                    .foregroundColor(.white)
                    .keyboardType(.numberPad)
                    .accentColor(.blue)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct QuickTargetButton: View {
    let value: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Voice Prompt Recorder
struct VoicePromptRecorder: View {
    let sebhaText: String
    @Binding var isRecording: Bool
    @ObservedObject var viewModel: SebhaViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            if sebhaText.isEmpty {
                InfoBox(
                    message: "Enter a sebha text first to record voice prompt",
                    icon: "info.circle.fill",
                    color: .blue
                )
            } else {
                Button(action: {
                    if isRecording {
                        viewModel.stopRecordingVoicePrompt()
                        isRecording = false
                    } else {
                        viewModel.startRecordingVoicePrompt(for: sebhaText)
                        isRecording = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title2)
                            .foregroundColor(isRecording ? .red : .purple)
                        
                        Text(isRecording ? "Stop Recording" : "Record Pronunciation")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if viewModel.hasVoiceRecording(for: sebhaText) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isRecording ? Color.red.opacity(0.2) : Color.purple.opacity(0.2))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isRecording ? Color.red : Color.purple, lineWidth: 2)
                    )
                }
                
                if viewModel.hasVoiceRecording(for: sebhaText) && !isRecording {
                    Button(action: {
                        viewModel.playVoicePrompt(for: sebhaText)
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Play Recording")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.green)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.2))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Info Box
struct InfoBox: View {
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary
        case secondary
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .foregroundColor(style == .primary ? .white : color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(style == .primary ? color : color.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color, lineWidth: style == .primary ? 0 : 2)
        )
        .shadow(
            color: style == .primary ? color.opacity(0.3) : .clear,
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

// MARK: - Validation Error View
struct ValidationErrorView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red, lineWidth: 1)
        )
    }
}

// MARK: - Success Animation View
struct SuccessAnimationView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Sebha Added!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.15, green: 0.2, blue: 0.3))
            )
        }
    }
}

struct AddSebhaSheetEnhanced_Previews: PreviewProvider {
    static var previews: some View {
        AddSebhaSheetEnhanced(
            viewModel: SebhaViewModel(),
            isPresented: .constant(true)
        )
    }
}
