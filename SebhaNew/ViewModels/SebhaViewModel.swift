import Foundation
import SwiftUI
import Speech
import AVFoundation
import AudioToolbox

protocol SebhaViewModelDelegate: AnyObject {
    func didReachTarget()
}
extension String {
    func removingInvisibleCharacters() -> String {
        // Remove common invisible Unicode characters
        var cleaned = self
        
        // Object Replacement Character (￼) - This is the main culprit
        cleaned = cleaned.replacingOccurrences(of: "\u{FFFC}", with: "")
        
        // Zero Width characters
        cleaned = cleaned.replacingOccurrences(of: "\u{200B}", with: "") // Zero Width Space
        cleaned = cleaned.replacingOccurrences(of: "\u{200C}", with: "") // Zero Width Non-Joiner
        cleaned = cleaned.replacingOccurrences(of: "\u{200D}", with: "") // Zero Width Joiner
        cleaned = cleaned.replacingOccurrences(of: "\u{FEFF}", with: "") // Zero Width No-Break Space (BOM)
        
        // Right-to-Left and Left-to-Right marks
        cleaned = cleaned.replacingOccurrences(of: "\u{200E}", with: "") // Left-to-Right Mark
        cleaned = cleaned.replacingOccurrences(of: "\u{200F}", with: "") // Right-to-Left Mark
        
        // Other control characters that might cause issues
        cleaned = cleaned.replacingOccurrences(of: "\u{202A}", with: "") // Left-to-Right Embedding
        cleaned = cleaned.replacingOccurrences(of: "\u{202B}", with: "") // Right-to-Left Embedding
        cleaned = cleaned.replacingOccurrences(of: "\u{202C}", with: "") // Pop Directional Formatting
        cleaned = cleaned.replacingOccurrences(of: "\u{202D}", with: "") // Left-to-Right Override
        cleaned = cleaned.replacingOccurrences(of: "\u{202E}", with: "") // Right-to-Left Override
        
        return cleaned.filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
    }
    
    func normalizedArabic() -> String {
        var normalized = self
        
        // First, remove invisible characters
        normalized = normalized.removingInvisibleCharacters()
        
        // Normalize different forms of Alif
        normalized = normalized.replacingOccurrences(of: "أ", with: "ا")  // Alif with hamza above
        normalized = normalized.replacingOccurrences(of: "إ", with: "ا")  // Alif with hamza below
        normalized = normalized.replacingOccurrences(of: "آ", with: "ا")  // Alif with madda
        normalized = normalized.replacingOccurrences(of: "ٱ", with: "ا")  // Alif wasla
        
        // Normalize different forms of Ya
        normalized = normalized.replacingOccurrences(of: "ي", with: "ى")  // Ya with dots
        normalized = normalized.replacingOccurrences(of: "ى", with: "ي")  // Alif maksura to Ya
        
        // Normalize different forms of Ta Marbuta
        normalized = normalized.replacingOccurrences(of: "ة", with: "ه")  // Ta marbuta to Ha
        
        // Remove diacritics (tashkeel)
        let diacritics = ["ً", "ٌ", "ٍ", "َ", "ُ", "ِ", "ّ", "ْ", "ٰ", "ٱ", "ٖ", "ٗ", "٘", "ٙ", "ٚ", "ٛ", "ٜ", "ٝ", "ٞ", "ٟ", "٠ ", "ٱ"]
        for diacritic in diacritics {
            normalized = normalized.replacingOccurrences(of: diacritic, with: "")
        }
        
        // Remove extra whitespaces and normalize spacing
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return normalized
    }
}
class SebhaViewModel: ObservableObject {
    weak var delegate: SebhaViewModelDelegate?
    
    @Published var selectedSebha = ""
    @Published var allSebhas: [String] = []
    @Published var currentTarget = 0
    private func switchToNextSebha() {
        guard !allSebhas.isEmpty else { return }
        
        let nextIndex = (currentIndex + 1) % allSebhas.count
        currentIndex = nextIndex
        selectedSebha = allSebhas[nextIndex]
        currentTarget = allSebhasTarget[nextIndex]
        counter = allSebhasCounter[nextIndex] // Use the actual current count for the next sebha
        
        // Update progress
        updateProgress()
        
        print("Switched to next sebha: \(selectedSebha) with current count: \(counter)")
        
        // Play voice prompt for the new sebha instead of showing alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.playVoicePrompt(for: self.selectedSebha)
        }
    }
    @Published var currentIndex = 0
    @Published var allSebhasTarget: [Int] = []
    @Published var allSebhasCounter: [Int] = []
    @Published var favoriteSebhas: [String] = []
    @Published var countHistory: [(date: Date, count: Int)] = []
    
    @Published var showEditTargetAlert = false
    @Published var editTargetSebhaIndex: Int? = nil
    @Published var newTarget = ""
    @Published var isRecordingForNewSebha = false
    @Published var Stopped = false
    @Published var before = 0
    @Published var counter = 0
    @Published var isVoice = false {
        didSet {
            if isVoice {
                startSpeechRecognition()
            } else {
                stopSpeechRecognition()
            }
        }
    }
    @Published var target = 0
    @Published var prevCount = 0
    @Published var targetInput = ""
    @Published var showAlert = false
    @Published var showAddSebhaAlert = false
    
    @Published var newSebha = ""
    @Published var newSebhaRecorded = ""
    @Published var newSebhaTarget = ""
    @Published var recognizedText = ""
    @Published var currentSebhaProgress: Double = 0.0
    
    // Voice recordings for each sebha
    @Published var sebhaRecordings: [String: URL] = [:]
    @Published var isRecordingVoicePrompt = false
    @Published var recordingForSebhaIndex: Int? = nil
    
    // Sound player for completion sound and voice prompts
    private var audioPlayer: AVAudioPlayer?
    private var voiceRecorder: AVAudioRecorder?
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    init() {
        loadSebhas()
        if allSebhas.isEmpty {
            allSebhas = ["سبحان الله", "الحمد لله", "لا اله الا الله"]
            allSebhasTarget = [10, 20, 30]
            allSebhasCounter = [0, 0, 0]
            favoriteSebhas = []
            selectedSebha = allSebhas[0]
            currentTarget = allSebhasTarget[0]
            saveSebhas()
        }
        selectedSebha = allSebhas[0]
        currentTarget = allSebhasTarget[0]
        currentIndex = 0
        counter = allSebhasCounter[0] // Set counter to the actual current count
        updateProgress()
        print("Initialization done")
        setupAudioSession()
        loadVoiceRecordings()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startSpeechRecognitionForNewSebha() {
        stopSpeechRecognition() // Ensure any existing recognition is stopped
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let spokenText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = spokenText
                    print("Recognized text: \(spokenText)")
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.stopSpeechRecognitionForNewSebha()
                print("Error or final result: \(String(describing: error))")
            }
        }
        
        // Use the input node's actual format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
            print("Audio buffer appended")
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecordingForNewSebha = true
            print("Audio engine started")
        } catch {
            print("Audio engine couldn't start because of an error: \(error.localizedDescription)")
        }
    }
    func stopSpeechRecognitionForNewSebha() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recognitionRequest = nil
            recognitionTask = nil
            isRecordingForNewSebha = false
            print("Audio engine stopped")
        }
    }
    
    
    // Example function to calculate weekly stats
    func calculateWeeklyStats() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let weeklyCounts = countHistory.filter { $0.date >= oneWeekAgo }
        return weeklyCounts.map { $0.count }.reduce(0, +)
    }
    
    // Example function to calculate monthly stats
    func calculateMonthlyStats() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
        
        let monthlyCounts = countHistory.filter { $0.date >= oneMonthAgo }
        return monthlyCounts.map { $0.count }.reduce(0, +)
    }
    
    // Example function to calculate daily stats
    func calculateDailyStats() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        let dailyCounts = countHistory.filter { calendar.isDate($0.date, inSameDayAs: today) }
        return dailyCounts.map { $0.count }.reduce(0, +)
    }
    
    // Ensure to update the countHistory whenever a count is incremented
    func incrementCount(for sebha: String) {
        counter += 1
        allSebhasCounter[currentIndex] += 1
        countHistory.append((date: Date(), count: 1))
        updateProgress()
        
        if counter >= currentTarget && currentTarget > 0 {
            triggerVibration()
            playCompletionSound()
            delegate?.didReachTarget()
            
            // Auto switch to next sebha after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.switchToNextSebha()
            }
        }
        saveSebhas()
    }
    
    private func updateProgress() {
        if currentTarget > 0 {
            currentSebhaProgress = min(Double(counter) / Double(currentTarget), 1.0)
        } else {
            currentSebhaProgress = 0.0
        }
    }
    
    func addFavoriteSebha(at index: Int) {
        let sebha = allSebhas[index]
        if favoriteSebhas.contains(sebha) {
            favoriteSebhas.removeAll { $0 == sebha }
        } else {
            favoriteSebhas.append(sebha)
        }
        saveSebhas()
    }
    
    func editSebhaTarget(at index: Int) {
        editTargetSebhaIndex = index
        newTarget = String(allSebhasTarget[index])
        showEditTargetAlert = true
    }
    
    func updateSebhaTarget() {
        guard let index = editTargetSebhaIndex, let targetValue = Int(newTarget) else {
            return
        }
        allSebhasTarget[index] = targetValue
        if selectedSebha == allSebhas[index] {
            currentTarget = targetValue
        }
        editTargetSebhaIndex = nil
        newTarget = ""
        saveSebhas()
    }
    
    func triggerVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func addCustomSebha() {
        guard !newSebha.isEmpty, !newSebhaTarget.isEmpty, let targetValue = Int(newSebhaTarget) else {
            print("Invalid new Sebha or target")
            return
        }
        
        allSebhas.append(newSebha)
        allSebhasTarget.append(targetValue)
        allSebhasCounter.append(0)
        
        newSebha = ""
        newSebhaTarget = ""
        
        currentIndex = allSebhas.count - 1
        selectedSebha = allSebhas.last!
        currentTarget = targetValue
        counter = 0
        updateProgress()
        
        print("New Sebha added:")
        saveSebhas()
    }
    
    func saveSebhas() {
        UserDefaults.standard.set(allSebhas, forKey: "allSebhas")
        UserDefaults.standard.set(allSebhasTarget, forKey: "allSebhasTarget")
        UserDefaults.standard.set(allSebhasCounter, forKey: "allSebhasCounter")
        UserDefaults.standard.set(favoriteSebhas, forKey: "favoriteSebhas")
        
        // Force synchronize to ensure data is written to disk
        UserDefaults.standard.synchronize()
        
        print("Data saved:")
        print("allSebhas: \(allSebhas)")
        print("allSebhasTarget: \(allSebhasTarget)")
        print("allSebhasCounter: \(allSebhasCounter)")
        print("favoriteSebhas: \(favoriteSebhas)")
    }
    
    func loadSebhas() {
        if let savedSebhas = UserDefaults.standard.stringArray(forKey: "allSebhas") {
            allSebhas = savedSebhas
        } else {
            allSebhas = ["سبحان الله", "الحمد لله", "لا اله الا الله"]
        }
        
        if let savedSebhasTarget = UserDefaults.standard.array(forKey: "allSebhasTarget") as? [Int] {
            allSebhasTarget = savedSebhasTarget
        } else {
            allSebhasTarget = [10, 20, 30]
        }
        
        if let savedSebhasCounter = UserDefaults.standard.array(forKey: "allSebhasCounter") as? [Int] {
            allSebhasCounter = savedSebhasCounter
        } else {
            allSebhasCounter = [0, 0, 0]
        }
        
        if let savedFavoriteSebhas = UserDefaults.standard.stringArray(forKey: "favoriteSebhas") {
            favoriteSebhas = savedFavoriteSebhas
        } else {
            favoriteSebhas = []
        }
        
        print("Data loaded:")
        print("allSebhas: \(allSebhas)")
        print("allSebhasTarget: \(allSebhasTarget)")
        print("allSebhasCounter: \(allSebhasCounter)")
        print("favoriteSebhas: \(favoriteSebhas)")
        
        if allSebhas.count != allSebhasTarget.count || allSebhas.count != allSebhasCounter.count {
            print("Inconsistent array lengths detected after loading")
        }
    }
    
    func removeSebha(at index: Int) {
        guard index < allSebhas.count else { return }
        
        allSebhas.remove(at: index)
        allSebhasTarget.remove(at: index)
        allSebhasCounter.remove(at: index)
        
        if allSebhas.isEmpty {
            selectedSebha = ""
            currentTarget = 0
            currentIndex = 0
        } else {
            if index <= currentIndex {
                // If we removed an item before or at current index, adjust current index
                currentIndex = max(0, currentIndex - 1)
            }
            // Ensure current index is within bounds
            currentIndex = min(currentIndex, allSebhas.count - 1)
            
            selectedSebha = allSebhas[currentIndex]
            currentTarget = allSebhasTarget[currentIndex]
        }
        updateProgress()
        saveSebhas()
    }
    
    func moveSebha(from source: IndexSet, to destination: Int) {
        // Make sure we have valid indices
        guard let sourceIndex = source.first,
              sourceIndex < allSebhas.count,
              destination <= allSebhas.count else { return }
        
        // Calculate the actual destination index
        let actualDestination = destination > sourceIndex ? destination - 1 : destination
        
        // Store the items to move
        let movedSebha = allSebhas[sourceIndex]
        let movedTarget = allSebhasTarget[sourceIndex]
        let movedCounter = allSebhasCounter[sourceIndex]
        
        // Remove from original position
        allSebhas.remove(at: sourceIndex)
        allSebhasTarget.remove(at: sourceIndex)
        allSebhasCounter.remove(at: sourceIndex)
        
        // Insert at new position
        allSebhas.insert(movedSebha, at: actualDestination)
        allSebhasTarget.insert(movedTarget, at: actualDestination)
        allSebhasCounter.insert(movedCounter, at: actualDestination)
        
        // Update current index if the currently selected item was moved
        if sourceIndex == currentIndex {
            currentIndex = actualDestination
        } else if sourceIndex < currentIndex && actualDestination >= currentIndex {
            currentIndex -= 1
        } else if sourceIndex > currentIndex && actualDestination <= currentIndex {
            currentIndex += 1
        }
        
        // Update selected sebha and target if current item changed
        if currentIndex < allSebhas.count {
            selectedSebha = allSebhas[currentIndex]
            currentTarget = allSebhasTarget[currentIndex]
            counter = allSebhasCounter[currentIndex] // Update counter to match the current sebha
        }
        
        // Update progress after moving
        updateProgress()
        
        saveSebhas()
        print("Moved sebha from \(sourceIndex) to \(actualDestination), current index now: \(currentIndex)")
        print("Updated counter to: \(counter) for sebha: \(selectedSebha)")
    }
    private var isRestarting = false // Added flag to prevent multiple restarts
    private func handleSpokenText(_ text: String) {
        // Debug current state
        print("=== VOICE RECOGNITION DEBUG ===")
        print("Current selectedSebha: '\(selectedSebha)'")
        print("Current index: \(currentIndex)")
        print("All sebhas: \(allSebhas)")
        print("Recognized text: '\(text)'")
        
        // Normalize Arabic text for both sebha and spoken text
        let sebhaPhrase = selectedSebha.trimmingCharacters(in: .whitespacesAndNewlines).normalizedArabic()
        let normalizedSpokenText = text.normalizedArabic()
        
        let sebhaWords = sebhaPhrase.split(separator: " ").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let spokenWords = normalizedSpokenText.split(separator: " ").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        print("Sebha phrase after trimming and normalization: '\(sebhaPhrase)'")
        print("Spoken text after normalization: '\(normalizedSpokenText)'")
        print("Sebha words: \(sebhaWords)")
        print("Spoken words: \(spokenWords)")
        print("Sebha words count: \(sebhaWords.count)")
        print("Spoken words count: \(spokenWords.count)")
        
        // Check if we have valid data
        guard !sebhaPhrase.isEmpty && !sebhaWords.isEmpty else {
            print("❌ ERROR: Selected sebha is empty or has no words!")
            return
        }
        
        guard !spokenWords.isEmpty else {
            print("❌ ERROR: No spoken words detected!")
            return
        }
        
        var matchCount = 0
        var i = 0
        
        while i <= spokenWords.count - sebhaWords.count {
            var isMatch = true
            for j in 0..<sebhaWords.count {
                let spokenWord = spokenWords[i + j]
                let sebhaWord = sebhaWords[j]
                print("Comparing: '\(spokenWord)' with '\(sebhaWord)'")
                if spokenWord.caseInsensitiveCompare(sebhaWord) != .orderedSame {
                    isMatch = false
                    print("No match at word \(i + j): '\(spokenWord)' != '\(sebhaWord)'")
                    break
                }
            }
            if isMatch {
                matchCount += 1
                print("Match found: \(Array(spokenWords[i..<i + sebhaWords.count]).joined(separator: " "))")
                i += sebhaWords.count // Move the index by the length of the phrase to avoid overlapping
            } else {
                print("No match: \(Array(spokenWords[i..<min(i + sebhaWords.count, spokenWords.count)]).joined(separator: " "))")
                i += 1
            }
        }
        
        print("Total matches found: \(matchCount)")
        
        let newMatchesCount = matchCount - before
        before = matchCount
        
        if newMatchesCount > 0 {
            counter += newMatchesCount
            allSebhasCounter[currentIndex] += newMatchesCount
            saveSebhas()
            
            print("New matches count: \(newMatchesCount)")
            print("Updated counter: \(counter)")
            print("All Sebhas counter: \(allSebhasCounter)")
            
            if counter >= currentTarget && currentTarget > 0 {
                triggerVibration()
                playCompletionSound()
                //showAlert = true
                delegate?.didReachTarget()
                
                // Auto switch to next sebha after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.switchToNextSebha()
                }
            }
        }
    }


        
    func startSpeechRecognition() {
        before = 0 // Reset the count before starting recognition
        
        // Stop any existing recognition
        if audioEngine.isRunning {
            stopSpeechRecognition()
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let spokenText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.handleSpokenText(spokenText)
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.stopSpeechRecognition()
            }
        }
        
        // Use the input node's actual format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("Speech recognition started successfully")
        } catch {
            print("audioEngine couldn't start because of an error: \(error.localizedDescription)")
        }
    }

    func stopSpeechRecognition() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recognitionRequest = nil
            recognitionTask = nil
        }
    }
    
    // MARK: - Sound Functions
    private func playCompletionSound() {
        // Play system sound for completion
        AudioServicesPlaySystemSound(1001) // Success sound
        
        // Optionally, you can also play a custom sound
        // guard let url = Bundle.main.url(forResource: "completion", withExtension: "mp3") else { return }
        // 
        // do {
        //     audioPlayer = try AVAudioPlayer(contentsOf: url)
        //     audioPlayer?.play()
        // } catch {
        //     print("Error playing completion sound: \(error)")
        // }
    }
    
    
    func selectSebha(at index: Int) {
        guard index < allSebhas.count else { return }
        
        currentIndex = index
        selectedSebha = allSebhas[index]
        currentTarget = allSebhasTarget[index]
        counter = allSebhasCounter[index] // Use the actual current count for this sebha
        updateProgress()
        saveSebhas()
    }
    
    // MARK: - Voice Recording Functions
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func getVoiceRecordingURL(for sebha: String) -> URL {
        let filename = sebha.replacingOccurrences(of: " ", with: "_") + "_voice.m4a"
        return getDocumentsDirectory().appendingPathComponent(filename)
    }
    
    func startRecordingVoicePrompt(for sebha: String) {
        guard let index = allSebhas.firstIndex(of: sebha) else {
            print("Could not find sebha in list: \(sebha)")
            return
        }
        
        recordingForSebhaIndex = index
        let recordingURL = getVoiceRecordingURL(for: sebha)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            voiceRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            voiceRecorder?.record()
            isRecordingVoicePrompt = true
            print("Started recording voice prompt for: \(sebha)")
        } catch {
            print("Could not start recording voice prompt: \(error)")
        }
    }
    
    func stopRecordingVoicePrompt() {
        guard let recorder = voiceRecorder, let index = recordingForSebhaIndex else { return }
        
        recorder.stop()
        isRecordingVoicePrompt = false
        
        let sebha = allSebhas[index]
        let recordingURL = getVoiceRecordingURL(for: sebha)
        sebhaRecordings[sebha] = recordingURL
        
        saveVoiceRecordings()
        print("Stopped recording voice prompt for: \(sebha)")
        
        voiceRecorder = nil
        recordingForSebhaIndex = nil
    }
    
    func playVoicePrompt(for sebha: String) {
        guard let recordingURL = sebhaRecordings[sebha] else {
            print("No voice recording found for: \(sebha)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.play()
            print("Playing voice prompt for: \(sebha)")
        } catch {
            print("Could not play voice prompt: \(error)")
        }
    }
    
    func hasVoiceRecording(for sebha: String) -> Bool {
        guard let url = sebhaRecordings[sebha] else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func deleteVoiceRecording(for sebha: String) {
        guard let recordingURL = sebhaRecordings[sebha] else { return }
        
        do {
            try FileManager.default.removeItem(at: recordingURL)
            sebhaRecordings.removeValue(forKey: sebha)
            saveVoiceRecordings()
            print("Deleted voice recording for: \(sebha)")
        } catch {
            print("Could not delete voice recording: \(error)")
        }
    }
    
    private func saveVoiceRecordings() {
        // Save only the filenames, not the full paths
        let recordings = sebhaRecordings.mapValues { url in
            url.lastPathComponent
        }
        UserDefaults.standard.set(recordings, forKey: "sebhaVoiceRecordings")
        UserDefaults.standard.synchronize() // Force synchronize
        print("Saved voice recordings: \(recordings)")
    }
    
    private func loadVoiceRecordings() {
        guard let savedRecordings = UserDefaults.standard.dictionary(forKey: "sebhaVoiceRecordings") as? [String: String] else { 
            print("No saved voice recordings found")
            return 
        }
        
        // Reconstruct full paths using current Documents directory
        sebhaRecordings = savedRecordings.compactMapValues { filename in
            let fullURL = getDocumentsDirectory().appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: fullURL.path) {
                print("Found voice recording file: \(fullURL.path)")
                return fullURL
            } else {
                print("Voice recording file not found: \(fullURL.path)")
                return nil
            }
        }
        
        print("Loaded voice recordings: \(sebhaRecordings.keys)")
    }
    
    // MARK: - Reset Functions
    func resetAllCurrentCounts() {
        // Reset all current session counts to 0
        allSebhasCounter = Array(repeating: 0, count: allSebhas.count)
        counter = 0
        
        // Update progress
        updateProgress()
        
        // Save changes
        saveSebhas()
        
        print("Reset all current counts for a new day")
    }
    
    func resetAllStatistics() {
        // Reset counters and history
        allSebhasCounter = Array(repeating: 0, count: allSebhas.count)
        counter = 0
        countHistory.removeAll()
        
        // Update progress
        updateProgress()
        
        // Save changes
        saveSebhas()
        
        print("Reset all statistics completely")
    }
}
