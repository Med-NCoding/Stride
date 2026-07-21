import Foundation

struct Utilities {
    
    // MARK: - Date Helpers
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    static func startOfWeek() -> Date {
        Calendar.current.dateLimit(limit: .start, for: Date()) ?? Date()
    }
    
    // MARK: - Number Formatters
    static func formatSteps(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: count)) ?? "\(count)") + " steps"
    }
    
    static func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedString = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "₿ " + formattedString
    }
}

// Helper calendar extensions
extension Calendar {
    enum Limit {
        case start
        case end
    }
    
    func dateLimit(limit: Limit, for referenceDate: Date) -> Date? {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
        guard let sunday = self.date(from: components) else { return nil }
        if limit == .start {
            return sunday
        } else {
            return self.date(byAdding: .day, value: 6, to: sunday)
        }
    }
}
