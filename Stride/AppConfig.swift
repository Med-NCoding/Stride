import Foundation

struct AppConfig {
    // Supabase Configuration loaded dynamically from Config.plist (gitignored)
    static let supabaseUrl: URL = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let urlString = dict["SUPABASE_URL"] as? String,
              let url = URL(string: urlString) else {
            return URL(string: "https://your-project.supabase.co")!
        }
        return url
    }()
    
    static let supabaseAnonKey: String = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["SUPABASE_ANON_KEY"] as? String else {
            return "your-anon-key-here"
        }
        return key
    }()
    
    // HealthKit Configuration
    static let stepGoalDailyDefault = 10000
    
    // Currency Configuration
    // Conversion rate: 1000 verified steps = 1 Stride virtual currency unit
    static let stepsPerCurrencyUnit = 1000.0
    
    // Environment settings
    static let isDevelopment = true
}
