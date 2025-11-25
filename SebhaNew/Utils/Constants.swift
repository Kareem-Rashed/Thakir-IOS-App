import Foundation

enum SebhaConstants {
    static let defaultSebhas = [
        "سبحان الله",
        "الحمد لله", 
        "لا إله إلا الله"
    ]
    
    static let defaultTargets = [33, 33, 33]
    
    static let userDefaultsKeys = UserDefaultsKeys()
    
    struct UserDefaultsKeys {
        let allSebhas = "allSebhas"
        let allSebhasTarget = "allSebhasTarget"
        let allSebhasCounter = "allSebhasCounter"
        let favoriteSebhas = "favoriteSebhas"
        let dailyStats = "dailyStats"
        let voiceRecordings = "voiceRecordings"
    }
    
    enum SpeechRecognition {
        static let locale = "ar-SA"
        static let bufferSize: UInt32 = 1024
    }
    
    enum Audio {
        static let completionSoundID: UInt32 = 1001
        static let audioSessionCategory = "AVAudioSessionCategoryPlayAndRecord"
    }
    
    enum Animation {
        static let springResponse: Double = 0.3
        static let springDamping: Double = 0.6
    }
}

enum SebhaError: LocalizedError {
    case speechRecognitionNotAvailable
    case audioEngineFailedToStart
    case invalidSebhaData
    case voiceRecordingFailed
    
    var errorDescription: String? {
        switch self {
        case .speechRecognitionNotAvailable:
            return "Speech recognition is not available on this device"
        case .audioEngineFailedToStart:
            return "Failed to start audio engine for speech recognition"
        case .invalidSebhaData:
            return "Invalid sebha data provided"
        case .voiceRecordingFailed:
            return "Failed to record voice prompt"
        }
    }
}
