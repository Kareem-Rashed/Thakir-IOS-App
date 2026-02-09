import Foundation
import SwiftUI

class AppLanguage: ObservableObject {
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    enum Language: String, CaseIterable {
        case arabic = "ar"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .arabic: return "العربية"
            case .english: return "English"
            }
        }
        
        var isRTL: Bool {
            self == .arabic
        }
    }
    
    static let shared = AppLanguage()
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Default to Arabic
            self.currentLanguage = .arabic
        }
    }
    
    // Localized strings
    func string(for key: LocalizedKey) -> String {
        switch currentLanguage {
        case .arabic:
            return key.arabic
        case .english:
            return key.english
        }
    }
}

enum LocalizedKey {
    case home
    case sebhas
    case profile
    case currentSebha
    case tapToCount
    case reset
    case target
    case progress
    case today
    case selectSebha
    case done
    case settings
    case language
    case darkMode
    case statistics
    case todayCount
    case weekCount
    case monthCount
    case allTimeCount
    case resetAllCounters
    case resetStatistics
    case cancel
    case confirm
    case addNewSebha
    case sebhaText
    case dailyTarget
    case voicePrompt
    case addSebha
    case edit
    case delete
    case mySebhas
    case current
    case createSebhaDesc
    case typeText
    case voiceInput
    case tapMicToSpeak
    case typeYourSebha
    case recordVoicePrompt
    case howManyTimes
    case optional
    case recordPronunciation
    case save
    case example
    case startRecording
    case stopRecording
    case listening
    case recognized
    
    var arabic: String {
        switch self {
        case .home: return "الرئيسية"
        case .sebhas: return "السبح"
        case .profile: return "الملف"
        case .currentSebha: return "السبحة الحالية"
        case .tapToCount: return "اضغط للعد"
        case .reset: return "إعادة تعيين"
        case .target: return "الهدف"
        case .progress: return "التقدم"
        case .today: return "اليوم"
        case .selectSebha: return "اختر السبحة"
        case .done: return "تم"
        case .settings: return "الإعدادات"
        case .language: return "اللغة"
        case .darkMode: return "الوضع الداكن"
        case .statistics: return "الإحصائيات"
        case .todayCount: return "اليوم"
        case .weekCount: return "هذا الأسبوع"
        case .monthCount: return "هذا الشهر"
        case .allTimeCount: return "كل الوقت"
        case .resetAllCounters: return "إعادة تعيين كل العدادات"
        case .resetStatistics: return "إعادة تعيين الإحصائيات"
        case .cancel: return "إلغاء"
        case .confirm: return "تأكيد"
        case .addNewSebha: return "إضافة سبحة جديدة"
        case .sebhaText: return "نص السبحة"
        case .dailyTarget: return "الهدف اليومي"
        case .voicePrompt: return "التنبيه الصوتي"
        case .addSebha: return "إضافة"
        case .edit: return "تعديل"
        case .delete: return "حذف"
        case .mySebhas: return "السبح"
        case .current: return "الحالي"
        case .createSebhaDesc: return "أنشئ سبحة بالنص أو الصوت"
        case .typeText: return "كتابة نص"
        case .voiceInput: return "إدخال صوتي"
        case .tapMicToSpeak: return "اضغط على الميكروفون للتحدث"
        case .typeYourSebha: return "اكتب سبحتك"
        case .recordVoicePrompt: return "سجل التنبيه الصوتي"
        case .howManyTimes: return "كم مرة في اليوم؟"
        case .optional: return "اختياري"
        case .recordPronunciation: return "سجل كيفية نطق هذه السبحة"
        case .save: return "حفظ"
        case .example: return "مثال: سبحان الله"
        case .startRecording: return "ابدأ التسجيل"
        case .stopRecording: return "إيقاف التسجيل"
        case .listening: return "جاري الاستماع..."
        case .recognized: return "تم التعرف على"
        }
    }
    
    var english: String {
        switch self {
        case .home: return "Home"
        case .sebhas: return "Sebhas"
        case .profile: return "Profile"
        case .currentSebha: return "Current Sebha"
        case .tapToCount: return "Tap to count"
        case .reset: return "Reset"
        case .target: return "Target"
        case .progress: return "Progress"
        case .today: return "Today"
        case .selectSebha: return "Select Sebha"
        case .done: return "Done"
        case .settings: return "Settings"
        case .language: return "Language"
        case .darkMode: return "Dark Mode"
        case .statistics: return "Statistics"
        case .todayCount: return "Today"
        case .weekCount: return "This Week"
        case .monthCount: return "This Month"
        case .allTimeCount: return "All Time"
        case .resetAllCounters: return "Reset All Counters"
        case .resetStatistics: return "Reset Statistics"
        case .cancel: return "Cancel"
        case .confirm: return "Confirm"
        case .addNewSebha: return "Add New Sebha"
        case .sebhaText: return "Sebha Text"
        case .dailyTarget: return "Daily Target"
        case .voicePrompt: return "Voice Prompt"
        case .addSebha: return "Add"
        case .edit: return "Edit"
        case .delete: return "Delete"
        case .mySebhas: return "My Sebhas"
        case .current: return "Current"
        case .createSebhaDesc: return "Create a sebha using text or voice"
        case .typeText: return "Type Text"
        case .voiceInput: return "Voice Input"
        case .tapMicToSpeak: return "Tap microphone to speak"
        case .typeYourSebha: return "Type your sebha"
        case .recordVoicePrompt: return "Record Voice Prompt"
        case .howManyTimes: return "How many times per day?"
        case .optional: return "Optional"
        case .recordPronunciation: return "Record how to pronounce this sebha"
        case .save: return "Save"
        case .example: return "e.g., سبحان الله"
        case .startRecording: return "Start Recording"
        case .stopRecording: return "Stop Recording"
        case .listening: return "Listening..."
        case .recognized: return "Recognized"
        }
    }
}
