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
        return self.filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
    }
    
    func normalizedArabic() -> String {
        var normalized = self
        
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
        
        // Remove extra whitespaces and invisible characters
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return normalized
    }
    
    // Advanced phonetic similarity for quick Arabic speech
    func phoneticSimilarity(to other: String) -> Double {
        let s1 = self.normalizedArabic().lowercased()
        let s2 = other.normalizedArabic().lowercased()
        
        if s1 == s2 { return 1.0 }
        
        // Levenshtein distance for fuzzy matching
        let len1 = s1.count
        let len2 = s2.count
        
        guard len1 > 0 && len2 > 0 else { return 0.0 }
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: len2 + 1), count: len1 + 1)
        
        for i in 0...len1 { matrix[i][0] = i }
        for j in 0...len2 { matrix[0][j] = j }
        
        let arr1 = Array(s1)
        let arr2 = Array(s2)
        
        for i in 1...len1 {
            for j in 1...len2 {
                let cost = arr1[i-1] == arr2[j-1] ? 0 : 1
                let deletion = matrix[i-1][j] + 1
                let insertion = matrix[i][j-1] + 1
                let substitution = matrix[i-1][j-1] + cost
                matrix[i][j] = Swift.min(deletion, Swift.min(insertion, substitution))
            }
        }
        
        let distance = matrix[len1][len2]
        let maxLen = Swift.max(len1, len2)
        return 1.0 - (Double(distance) / Double(maxLen))
    }
}
class SebhaViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
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
        
        // CRITICAL: Completely stop voice recognition and wait for full shutdown
        let wasRecognizing = isVoice
        if wasRecognizing {
            stopSpeechRecognition()
        }
        
        // Reset voice recognition state for new sebha
        lastRecognizedText = ""
        processingBuffer.removeAll()
        
        // Wait longer to ensure audio engine is fully stopped before playing audio
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Double-check that audio engine is stopped
            if self.audioEngine.isRunning {
                print("⚠️ Audio engine still running, forcing stop...")
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
            }
            
            // Now safe to play audio - pass wasRecognizing flag
            self.announceNewSebha(shouldRestartRecognition: wasRecognizing)
        }
    }
    @Published var currentIndex = 0
    @Published var allSebhasTarget: [Int] = []
    @Published var allSebhasCounter: [Int] = []
    @Published var favoriteSebhas: [String] = []
    @Published var countHistory: [(date: Date, count: Int)] = []
    
    // Per-sebha statistics tracking
    @Published var perSebhaStats: [String: SebhaStatistics] = [:]
    
    // Enhanced statistics tracking
    @Published var todayTotal: Int = 0
    @Published var weekTotal: Int = 0
    @Published var monthTotal: Int = 0
    @Published var allTimeTotal: Int = 0
    
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
    
    // Enhanced voice recognition tracking - Tarteel-style system
    private var lastRecognizedText = ""
    private var processingBuffer: [String] = []
    private var lastProcessTime = Date()
    private let minProcessInterval: TimeInterval = 0.1 // Process every 100ms for quick detection
    private var isPlayingAudio = false // Flag to prevent recognition restart during playback
    private var shouldRestartRecognitionAfterPlayback = false // Track if recognition should restart after audio
    
    // Tarteel-style recognition state machine
    private enum RecognitionState {
        case idle           // Not listening or just started
        case listening      // Actively listening for phrase
        case matched        // Found a match, waiting for completion
        case cooldown       // Brief pause after counting to prevent duplicates
    }
    
    private var recognitionState: RecognitionState = .idle
    private var matchConfidenceThreshold: Double = 0.75 // 75% similarity required (faster matching)
    private var partialMatchBuffer: [String] = []
    private var lastMatchTimestamp: Date?
    private let matchCooldownInterval: TimeInterval = 0.4 // 400ms between counts (faster)
    
    // Rate limiting for counting
    private var lastIncrementTime: Date?
    private let minimumTimeBetweenIncrements: TimeInterval = 0.3 // 300ms minimum between counts (faster)
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
    private var speechSynthesizer = AVSpeechSynthesizer()
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    override init() {
        super.init()
        loadSebhas()
        loadPerSebhaStats()
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
        updateStatistics()
        print("Initialization done")
        setupAudioSession()
        loadVoiceRecordings()
        loadPerSebhaStats()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Use .playAndRecord to allow both playback and microphone
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Initial audio session configured")
        } catch {
            print("❌ Failed to setup audio session: \(error.localizedDescription)")
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
    
    // Update all statistics
    private func updateStatistics() {
        todayTotal = calculateDailyStats()
        weekTotal = calculateWeeklyStats()
        monthTotal = calculateMonthlyStats()
        allTimeTotal = allSebhasCounter.reduce(0, +)
    }
    
    // Ensure to update the countHistory whenever a count is incremented
    func incrementCount(for sebha: String) {
        counter += 1
        allSebhasCounter[currentIndex] += 1
        countHistory.append((date: Date(), count: 1))
        
        // Update per-sebha statistics
        if perSebhaStats[sebha] == nil {
            perSebhaStats[sebha] = SebhaStatistics()
        }
        perSebhaStats[sebha]?.increment(by: 1)
        
        updateProgress()
        updateStatistics()
        
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
    
    func updateProgress() {
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
        
        // Save per-sebha statistics
        savePerSebhaStats()
        
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
    
    // MARK: - Tarteel-Style Voice Recognition System
    
    private func handleSpokenText(_ text: String) {
        let now = Date()
        
        // Validate input
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Normalize Arabic text (critical for matching)
        let normalizedSpoken = text.normalizedArabic().lowercased()
        let normalizedTarget = selectedSebha.normalizedArabic().lowercased()
        
        print("🎤 Input: '\(text)'")
        print("🔄 Normalized: '\(normalizedSpoken)'")
        print("🎯 Target: '\(normalizedTarget)'")
        print("📊 State: \(recognitionState)")
        
        // COOLDOWN CHECK: Prevent rapid duplicate counts
        if recognitionState == .cooldown {
            if let lastMatch = lastMatchTimestamp,
               now.timeIntervalSince(lastMatch) < matchCooldownInterval {
                print("❄️ In cooldown period, ignoring input")
                return
            } else {
                // Cooldown expired, reset to listening
                recognitionState = .listening
                partialMatchBuffer.removeAll()
            }
        }
        
        // Initialize state if needed
        if recognitionState == .idle {
            recognitionState = .listening
        }
        
        // TARTEEL APPROACH: Match on final results, not partials
        // This prevents counting partial speech as complete phrases
        
        // Check if this is exactly the same as what we just processed
        if normalizedSpoken == lastRecognizedText {
            print("⏭️ Exact duplicate input")
            return
        }
        
        // MATCHING STRATEGY: Use Tarteel's approach
        // 1. Check for complete phrase match
        let phraseMatch = checkPhraseMatch(spoken: normalizedSpoken, target: normalizedTarget)
        
        if phraseMatch.isMatch {
            print("✅ MATCH FOUND! Confidence: \(String(format: "%.1f%%", phraseMatch.confidence * 100))")
            
            // Verify this is a new, complete utterance
            if recognitionState == .listening {
                handleSuccessfulMatch(normalizedSpoken)
            }
            return
        }
        
        // 2. Build up partial buffer for compound phrases
        partialMatchBuffer.append(normalizedSpoken)
        
        // Keep buffer manageable
        if partialMatchBuffer.count > 5 {
            partialMatchBuffer.removeFirst()
        }
        
        // Check if combined buffer matches
        let combinedBuffer = partialMatchBuffer.joined(separator: " ")
        let bufferMatch = checkPhraseMatch(spoken: combinedBuffer, target: normalizedTarget)
        
        if bufferMatch.isMatch {
            print("✅ BUFFER MATCH! Confidence: \(String(format: "%.1f%%", bufferMatch.confidence * 100))")
            handleSuccessfulMatch(combinedBuffer)
            return
        }
        
        // Update last recognized for next comparison
        lastRecognizedText = normalizedSpoken
        
        print("❌ No match (best confidence: \(String(format: "%.1f%%", max(phraseMatch.confidence, bufferMatch.confidence) * 100)))")
    }
    
    // Tarteel-style phrase matching algorithm
    private func checkPhraseMatch(spoken: String, target: String) -> (isMatch: Bool, confidence: Double) {
        // Handle empty cases
        guard !spoken.isEmpty && !target.isEmpty else {
            return (false, 0.0)
        }
        
        // Split into words for analysis
        let spokenWords = spoken.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let targetWords = target.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard !spokenWords.isEmpty && !targetWords.isEmpty else {
            return (false, 0.0)
        }
        
        // METHOD 1: Exact substring match (highest priority)
        if spoken.contains(target) || target.contains(spoken) {
            let confidence = Double(min(spoken.count, target.count)) / Double(max(spoken.count, target.count))
            if confidence >= 0.65 { // Lower threshold for speed
                return (true, confidence)
            }
        }
        
        // METHOD 2: Sequential word matching (Tarteel's core algorithm)
        var matchedWords = 0
        var targetWordIndex = 0
        
        for spokenWord in spokenWords {
            // Check if this spoken word matches the current target word
            if targetWordIndex < targetWords.count {
                let targetWord = targetWords[targetWordIndex]
                
                // Exact match
                if spokenWord == targetWord {
                    matchedWords += 1
                    targetWordIndex += 1
                    continue
                }
                
                // Contains match (for longer words)
                if spokenWord.contains(targetWord) || targetWord.contains(spokenWord) {
                    matchedWords += 1
                    targetWordIndex += 1
                    continue
                }
                
                // Phonetic similarity match
                let similarity = spokenWord.phoneticSimilarity(to: targetWord)
                if similarity >= 0.75 { // Lower threshold for faster matching
                    matchedWords += 1
                    targetWordIndex += 1
                    continue
                }
            }
        }
        
        // Calculate confidence based on matched words
        let wordMatchRatio = Double(matchedWords) / Double(targetWords.count)
        
        // Require at least 75% of words to match (faster)
        if wordMatchRatio >= 0.75 {
            return (true, wordMatchRatio)
        }
        
        // METHOD 3: Levenshtein distance for whole phrase (fallback)
        let overallSimilarity = spoken.phoneticSimilarity(to: target)
        
        if overallSimilarity >= matchConfidenceThreshold {
            return (true, overallSimilarity)
        }
        
        // No match found
        return (false, max(wordMatchRatio, overallSimilarity))
    }
    
    // Handle a successful match
    private func handleSuccessfulMatch(_ matchedText: String) {
        // Update state
        recognitionState = .matched
        lastRecognizedText = matchedText
        lastMatchTimestamp = Date()
        
        // Clear buffer
        partialMatchBuffer.removeAll()
        
        // Increment counter with rate limiting
        incrementCounterWithRateLimit()
        
        // Enter cooldown to prevent immediate re-counting
        recognitionState = .cooldown
    }
    
    // Rate-limited counter increment
    private func incrementCounterWithRateLimit() {
        let now = Date()
        
        // Check rate limit
        if let lastTime = lastIncrementTime {
            let timeSinceLastIncrement = now.timeIntervalSince(lastTime)
            if timeSinceLastIncrement < minimumTimeBetweenIncrements {
                print("⏱️ Rate limit: \(String(format: "%.1f", timeSinceLastIncrement))s since last (min: \(minimumTimeBetweenIncrements)s)")
                return
            }
        }
        
        // Update timestamp
        lastIncrementTime = now
        
        // Increment counter
        if currentIndex < allSebhasCounter.count {
            allSebhasCounter[currentIndex] += 1
            counter = allSebhasCounter[currentIndex]
            
            // Update statistics
            var stats = perSebhaStats[selectedSebha] ?? SebhaStatistics()
            stats.increment()
            perSebhaStats[selectedSebha] = stats
            
            // Update totals
            todayTotal += 1
            weekTotal += 1
            monthTotal += 1
            allTimeTotal += 1
            
            // Add to history
            countHistory.append((date: Date(), count: 1))
            
            // Update progress
            updateProgress()
            
            // Haptic feedback
            triggerVibration()
            
            // Save
            saveSebhas()
            savePerSebhaStats()
            
            print("✅ Counter incremented to: \(counter)")
            
            // Check if target reached
            if counter >= currentTarget {
                handleTargetReached()
            }
        }
    }
    
    // Helper function for target reached
    private func handleTargetReached() {
        playCompletionSound()
        delegate?.didReachTarget()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.switchToNextSebha()
        }
    }
    
    // Exact matching algorithm - requires perfect match
    private func countExactMatches(sebhaWords: [String], spokenWords: [String]) -> Int {
        var count = 0
        var i = 0
        
        while i <= spokenWords.count - sebhaWords.count {
            var matched = true
            for j in 0..<sebhaWords.count {
                if spokenWords[i + j] != sebhaWords[j] {
                    matched = false
                    break
                }
            }
            if matched {
                count += 1
                i += sebhaWords.count
                print("  ✓ Exact match at position \(i)")
            } else {
                i += 1
            }
        }
        
        return count
    }
    
    // Fuzzy matching - allows minor pronunciation variations
    private func countFuzzyMatches(sebhaWords: [String], spokenWords: [String]) -> Int {
        let threshold = 0.80 // 80% similarity required
        var count = 0
        var i = 0
        
        while i <= spokenWords.count - sebhaWords.count {
            var totalSimilarity = 0.0
            for j in 0..<sebhaWords.count {
                let similarity = spokenWords[i + j].phoneticSimilarity(to: sebhaWords[j])
                totalSimilarity += similarity
            }
            
            let averageSimilarity = totalSimilarity / Double(sebhaWords.count)
            
            if averageSimilarity >= threshold {
                count += 1
                i += sebhaWords.count
                print("  ≈ Fuzzy match at position \(i) (similarity: \(Int(averageSimilarity * 100))%)")
            } else {
                i += 1
            }
        }
        
        return count
    }
    
    // Partial matching - for very fast/abbreviated speech
    private func countPartialMatches(sebhaPhrase: String, spokenWords: [String]) -> Int {
        let threshold = 0.75 // 75% similarity for partial matches
        var count = 0
        
        // Check if any single word has high similarity to the entire phrase
        for word in spokenWords {
            let similarity = word.phoneticSimilarity(to: sebhaPhrase)
            if similarity >= threshold {
                count += 1
                print("  ~ Partial match: '\(word)' (similarity: \(Int(similarity * 100))%)")
            }
        }
        
        return count
    }


        
    func startSpeechRecognition() {
        // Reset state
        lastRecognizedText = ""
        processingBuffer.removeAll()
        lastProcessTime = Date()
        
        // Stop any existing recognition completely
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Clear old tasks
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Wait a bit for cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Configure audio session BEFORE accessing input node
            do {
                let audioSession = AVAudioSession.sharedInstance()
                
                // CRITICAL: Use .playAndRecord NOT .record
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
                try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
                print("✅ Audio session configured for speech recognition")
            } catch {
                print("❌ Failed to configure audio session: \(error.localizedDescription)")
                return
            }
            
            // Check authorization
            let authStatus = SFSpeechRecognizer.authorizationStatus()
            guard authStatus == .authorized else {
                print("❌ Speech recognition not authorized: \(authStatus.rawValue)")
                if authStatus == .notDetermined {
                    SFSpeechRecognizer.requestAuthorization { status in
                        if status == .authorized {
                            DispatchQueue.main.async {
                                self.startSpeechRecognition()
                            }
                        }
                    }
                }
                return
            }
            
            self.startRecognitionEngine()
        }
    }
    
    private func startRecognitionEngine() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Unable to create recognition request")
            return
        }
        
        // Configure for continuous, real-time recognition
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation // Better for short phrases
        
        // Enhanced recognition settings for Arabic
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false // Use server for better accuracy
        }
        
        // Add context words to improve recognition
        if #available(iOS 16, *) {
            recognitionRequest.addsPunctuation = false
            let contextStrings = allSebhas.map { $0.normalizedArabic() }
            recognitionRequest.contextualStrings = contextStrings
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let spokenText = result.bestTranscription.formattedString
                isFinal = result.isFinal
                
                DispatchQueue.main.async {
                    self.handleSpokenText(spokenText)
                }
            }
            
            if let error = error {
                let nsError = error as NSError
                print("⚠️ Recognition error: \(error.localizedDescription) (Code: \(nsError.code))")
                
                // Only restart on specific errors, not 1101
                if nsError.code == 1107 {
                    print("❌ Audio session error 1107 - stopping")
                    DispatchQueue.main.async {
                        self.stopSpeechRecognition()
                    }
                }
            }
            
            if isFinal {
                // Restart recognition faster for continuous listening
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if self.isVoice && !self.audioEngine.isRunning && !self.isPlayingAudio {
                        self.startSpeechRecognition()
                    }
                }
            }
        }
        
        // Get input node AFTER audio session is configured
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Validate format before installing tap
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("❌ Invalid audio format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
            return
        }
        
        print("✅ Using audio format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
        
        // Install tap with smaller buffer for faster processing
        inputNode.installTap(onBus: 0, bufferSize: 512, format: recordingFormat) { [weak self] buffer, when in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("🎤 Speech recognition started (enhanced mode)")
            print("🎙️ Microphone is now listening...")
        } catch {
            print("❌ Audio engine couldn't start: \(error.localizedDescription)")
            // Clean up on failure
            inputNode.removeTap(onBus: 0)
        }
    }

    func stopSpeechRecognition() {
        // Stop in the correct order to prevent crashes
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // Then stop recognition
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Reset state - Tarteel-style cleanup
        lastRecognizedText = ""
        processingBuffer.removeAll()
        partialMatchBuffer.removeAll()
        recognitionState = .idle
        lastMatchTimestamp = nil
        
        print("🛑 Speech recognition stopped and state reset")
    }
    
    // MARK: - Sound Functions
    private func playCompletionSound() {
        // Play system sound for completion
        AudioServicesPlaySystemSound(1001) // Success sound
    }
    
    // Announce new sebha using Text-to-Speech
    private func announceNewSebha(shouldRestartRecognition: Bool = false) {
        // Don't try to stop recognition if it was already stopped by caller
        let wasRecognizing = shouldRestartRecognition ? shouldRestartRecognition : isVoice
        
        // Only stop if we're handling it ourselves (not pre-stopped)
        if !shouldRestartRecognition && wasRecognizing {
            stopSpeechRecognition()
        }
        
        print("🔊 Announcing new sebha: \(selectedSebha) (will restart recognition: \(wasRecognizing))")
        
        // First try to play recorded voice prompt
        if hasVoiceRecording(for: selectedSebha) {
            // playVoicePrompt already handles audio session and recognition restart
            playVoicePrompt(for: selectedSebha, shouldRestartRecognition: wasRecognizing)
            return
        }
        
        // Set flag to prevent premature restart
        isPlayingAudio = true
        
        // Fallback to Text-to-Speech announcement
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ Failed to set audio session for TTS: \(error)")
            isPlayingAudio = false
            // Restore recognition if setup fails
            if wasRecognizing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startSpeechRecognition()
                }
            }
            return
        }
        
        let utterance = AVSpeechUtterance(string: selectedSebha)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.5 // Speak slower for clarity
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        
        // Stop any current speech
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        speechSynthesizer.speak(utterance)
        print("🔊 TTS Announcing: \(selectedSebha)")
        
        // Restore speech recognition after TTS completes
        // Estimate duration based on text length
        let estimatedDuration = Double(selectedSebha.count) * 0.15 + 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) {
            self.isPlayingAudio = false
            
            // Restore audio session for recording
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
                try audioSession.setActive(true)
                print("✅ Audio session restored after TTS")
            } catch {
                print("❌ Failed to restore audio session after TTS: \(error)")
            }
            
            if wasRecognizing {
                print("🔄 Restarting voice recognition after TTS")
                self.startSpeechRecognition()
            }
        }
    }
    
    
    func selectSebha(at index: Int) {
        guard index < allSebhas.count else { return }
        
        currentIndex = index
        selectedSebha = allSebhas[index]
        currentTarget = allSebhasTarget[index]
        counter = allSebhasCounter[index] // Use the actual current count for this sebha
        
        // Reset voice recognition state when changing sebha
        lastRecognizedText = ""
        processingBuffer.removeAll()
        lastProcessTime = Date()
        
        updateProgress()
        saveSebhas()
        
        print("✅ Selected sebha: \(selectedSebha) (index: \(index), counter: \(counter))")
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
        
        // Stop any ongoing speech recognition
        if isVoice {
            stopSpeechRecognition()
        }
        
        // Stop audio player if running
        audioPlayer?.stop()
        audioPlayer = nil
        
        recordingForSebhaIndex = index
        let recordingURL = getVoiceRecordingURL(for: sebha)
        
        // Delete existing file if it exists
        if FileManager.default.fileExists(atPath: recordingURL.path) {
            try? FileManager.default.removeItem(at: recordingURL)
        }
        
        // Configure audio session for recording
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Audio session configured for recording")
        } catch {
            print("❌ Failed to setup audio session for recording: \(error)")
            return
        }
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        do {
            voiceRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            voiceRecorder?.prepareToRecord()
            voiceRecorder?.record()
            isRecordingVoicePrompt = true
            print("🎙️ Started recording voice prompt for: \(sebha)")
        } catch {
            print("❌ Could not start recording voice prompt: \(error)")
            recordingForSebhaIndex = nil
        }
    }
    
    func stopRecordingVoicePrompt() {
        guard let recorder = voiceRecorder, let index = recordingForSebhaIndex else { return }
        
        recorder.stop()
        isRecordingVoicePrompt = false
        
        let sebha = allSebhas[index]
        let recordingURL = getVoiceRecordingURL(for: sebha)
        
        // Wait a bit for the file to be finalized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Verify the file exists and is valid
            if FileManager.default.fileExists(atPath: recordingURL.path) {
                self.sebhaRecordings[sebha] = recordingURL
                self.saveVoiceRecordings()
                print("✅ Saved voice recording for: \(sebha)")
                print("   File path: \(recordingURL.path)")
                
                // Restore audio session to default state
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
                    try audioSession.setActive(true)
                } catch {
                    print("Failed to restore audio session: \(error)")
                }
            } else {
                print("❌ Recording file does not exist at: \(recordingURL.path)")
            }
        }
        
        voiceRecorder = nil
        recordingForSebhaIndex = nil
    }
    
    func playVoicePrompt(for sebha: String, shouldRestartRecognition: Bool = false) {
        guard let recordingURL = sebhaRecordings[sebha] else {
            print("No voice recording found for: \(sebha)")
            return
        }
        
        // Verify file exists before attempting playback
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            print("❌ Recording file does not exist at: \(recordingURL.path)")
            sebhaRecordings.removeValue(forKey: sebha)
            saveVoiceRecordings()
            return
        }
        
        // Use the passed parameter or default to current state
        let wasRecognizing = shouldRestartRecognition ? shouldRestartRecognition : isVoice
        
        // Only stop if we're handling it ourselves (not pre-stopped)
        if !shouldRestartRecognition && wasRecognizing {
            stopSpeechRecognition()
        }
        
        print("🔊 Playing voice prompt (will restart recognition: \(wasRecognizing))")
        
        // Store flag for delegate to use after playback completes
        shouldRestartRecognitionAfterPlayback = wasRecognizing
        
        // Set flag to prevent premature restart
        isPlayingAudio = true
        
        do {
            // Configure audio session for playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
            
            // Load audio file data first to verify it's valid
            let audioData = try Data(contentsOf: recordingURL)
            print("📁 Audio file size: \(audioData.count) bytes")
            
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 1.0
            
            // Set delegate to handle playback completion
            audioPlayer?.delegate = self
            
            let success = audioPlayer?.play() ?? false
            if success {
                let duration = audioPlayer?.duration ?? 2.0
                print("🔊 Playing voice prompt for: \(sebha) (duration: \(duration)s)")
                
                // Safety timeout: if delegate doesn't fire within expected time, force cleanup
                // This prevents the app from getting stuck if playback fails silently
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 2.0) {
                    if self.isPlayingAudio {
                        print("⚠️ Audio playback timeout - forcing cleanup")
                        self.isPlayingAudio = false
                        
                        // Use stored flag instead of wasRecognizing local variable
                        if self.shouldRestartRecognitionAfterPlayback {
                            do {
                                let audioSession = AVAudioSession.sharedInstance()
                                try audioSession.setCategory(.record, mode: .measurement, options: [.allowBluetooth])
                                try audioSession.setActive(true)
                            } catch {
                                print("❌ Failed to restore audio session: \(error)")
                            }
                            
                            if !self.audioEngine.isRunning {
                                self.startSpeechRecognition()
                            }
                            
                            // Clear flag after use
                            self.shouldRestartRecognitionAfterPlayback = false
                        }
                    }
                }
            } else {
                print("❌ Failed to start playback")
                isPlayingAudio = false
                shouldRestartRecognitionAfterPlayback = false // Clear flag on failure
                
                // Restore recognition even if playback fails
                if wasRecognizing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.startSpeechRecognition()
                    }
                }
            }
        } catch {
            print("❌ Could not play voice prompt: \(error)")
            print("   File path: \(recordingURL.path)")
            print("   Error code: \((error as NSError).code)")
            
            isPlayingAudio = false
            shouldRestartRecognitionAfterPlayback = false // Clear flag on error
            
            // Try to remove corrupted file
            try? FileManager.default.removeItem(at: recordingURL)
            sebhaRecordings.removeValue(forKey: sebha)
            saveVoiceRecordings()
            
            // Restore recognition even on error
            if wasRecognizing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startSpeechRecognition()
                }
            }
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
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🔊 Audio playback finished (success: \(flag))")
        isPlayingAudio = false
        
        // Use stored flag instead of current isVoice state
        // This is crucial because isVoice may have been changed before playback completed
        if shouldRestartRecognitionAfterPlayback {
            print("🔄 Will restart recognition after audio (flag was set)")
            
            // ENHANCED: Longer delay with full cleanup (2.0s total)
            // This prevents error 1107 by giving iOS adequate time
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    
                    // CRITICAL: Fully deactivate with proper cleanup
                    try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
                    print("🔄 Audio session deactivated completely")
                    
                    // Longer delay for hardware to settle (0.5s)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        do {
                            // Reconfigure with full options for recording
                            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
                            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
                            print("✅ Audio session restored for voice recognition (delegate)")
                            
                            // Additional delay before restarting engine (0.8s)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                // Final check before restart
                                if self.shouldRestartRecognitionAfterPlayback {
                                    // Ensure engine is fully stopped
                                    if self.audioEngine.isRunning {
                                        self.audioEngine.stop()
                                        self.audioEngine.inputNode.removeTap(onBus: 0)
                                    }
                                    
                                    // Small delay after stopping (0.3s)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        print("🔄 Restarting speech recognition after audio playback")
                                        self.startSpeechRecognition()
                                        // Clear the flag after successful restart
                                        self.shouldRestartRecognitionAfterPlayback = false
                                    }
                                }
                            }
                        } catch {
                            print("❌ Failed to reactivate audio session: \(error.localizedDescription)")
                            self.shouldRestartRecognitionAfterPlayback = false
                            
                            // Retry once after longer delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                if self.shouldRestartRecognitionAfterPlayback {
                                    self.startSpeechRecognition()
                                    self.shouldRestartRecognitionAfterPlayback = false
                                }
                            }
                        }
                    }
                } catch {
                    print("❌ Failed to deactivate audio session: \(error.localizedDescription)")
                    self.shouldRestartRecognitionAfterPlayback = false
                }
            }
        } else {
            print("ℹ️ Not restarting recognition (flag not set)")
            // Clear flag just in case
            shouldRestartRecognitionAfterPlayback = false
        }
    }
    
    // MARK: - Per-Sebha Statistics Persistence
    
    func savePerSebhaStats() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(perSebhaStats)
            UserDefaults.standard.set(data, forKey: "perSebhaStats")
            print("Per-sebha stats saved: \(perSebhaStats.count) sebhas")
        } catch {
            print("Error saving per-sebha stats: \(error)")
        }
    }
    
    func loadPerSebhaStats() {
        guard let data = UserDefaults.standard.data(forKey: "perSebhaStats") else {
            print("No saved per-sebha stats found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            perSebhaStats = try decoder.decode([String: SebhaStatistics].self, from: data)
            print("Per-sebha stats loaded: \(perSebhaStats.count) sebhas")
            updateStatistics()
        } catch {
            print("Error loading per-sebha stats: \(error)")
        }
    }
}
