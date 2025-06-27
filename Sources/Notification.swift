import Foundation

struct Notification {
    public func checkForNotification(domain: DomainWatched) {
        guard let expiryDate = domain.expiryDate else {
            print("[WARN] No expiry date available for domain: \(domain.domain)")
            return
        }

        let currentDate = Date()
        let calendar = Calendar.current

        if calendar.isDate(expiryDate, inSameDayAs: currentDate.addingTimeInterval(7 * 24 * 60 * 60)) {
            print("[ALERT] Domain \(domain.domain) expires in 7 days!")
        } else if calendar.isDate(expiryDate, inSameDayAs: currentDate.addingTimeInterval(14 * 24 * 60 * 60)) {
            print("[ALERT] Domain \(domain.domain) expires in 14 days!")
        } else if calendar.isDate(expiryDate, inSameDayAs: currentDate.addingTimeInterval(30 * 24 * 60 * 60)) {
            print("[ALERT] Domain \(domain.domain) expires in 30 days!")
        }
    }
}