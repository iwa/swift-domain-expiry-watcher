import AsyncHTTPClient
import Foundation

struct Notification {
    enum AlertType {
        case sevenDays, fourteenDays, thirtyDays
    }

    struct TelegramMessage: Codable {
        let chatId: String
        let text: String
        let parseMode: String
        let disableNotification: Bool
        let protectContent: Bool

        enum CodingKeys: String, CodingKey {
            case chatId = "chat_id"
            case text
            case parseMode = "parse_mode"
            case disableNotification = "disable_notification"
            case protectContent = "protect_content"
        }
    }

    public func checkForNotification(domain: DomainWatched) {
        guard let expiryDate = domain.expiryDate else {
            print("[WARN] No expiry date available for domain: \(domain.domain)")
            return
        }

        let currentDate = Date()
        let calendar = Calendar.current

        if calendar.isDate(
            expiryDate, inSameDayAs: currentDate.addingTimeInterval(7 * 24 * 60 * 60))
        {
            sendNotification(domain: domain, alertType: .sevenDays)
        } else if calendar.isDate(
            expiryDate, inSameDayAs: currentDate.addingTimeInterval(14 * 24 * 60 * 60))
        {
            sendNotification(domain: domain, alertType: .fourteenDays)
        } else if calendar.isDate(
            expiryDate, inSameDayAs: currentDate.addingTimeInterval(30 * 24 * 60 * 60))
        {
            sendNotification(domain: domain, alertType: .thirtyDays)
        }
    }

    func sendNotification(domain: DomainWatched, alertType: AlertType) {
        switch alertType {
        case .sevenDays:
            print("[NOTIFICATION] Domain \(domain.domain) expires in 7 days!")
        case .fourteenDays:
            print("[NOTIFICATION] Domain \(domain.domain) expires in 14 days!")
        case .thirtyDays:
            print("[NOTIFICATION] Domain \(domain.domain) expires in 30 days!")
        }
    }

    func sendTelegramNotification(domain: DomainWatched, alertType: AlertType) async throws {
        print("[INFO] Notification: triggered Telegram")

        guard let telegramChatId = ProcessInfo.processInfo.environment["TELEGRAM_CHAT_ID"] else {
            print("TELEGRAM_CHAT_ID environment variable not set")
            return
        }

        guard let telegramBotToken = ProcessInfo.processInfo.environment["TELEGRAM_BOT_TOKEN"] else {
            print("TELEGRAM_BOT_TOKEN environment variable not set")
            return
        }

        let payload = TelegramMessage(
            chatId: telegramChatId,
            text: "<b>⚠️ Domain \(domain.domain) expires in \(alertType) days!</b>",
            parseMode: "HTML",
            disableNotification: true,
            protectContent: false
        )

        let jsonData = try JSONEncoder().encode(payload)

        var request = HTTPClientRequest(
            url: "https://api.telegram.org/bot\(telegramBotToken)/sendMessage")
        request.method = .POST
        request.headers.add(name: "Content-Type", value: "application/json")
        request.body = .bytes(jsonData)

        let response = try await HTTPClient.shared.execute(request, timeout: .seconds(10))
        if response.status == .ok {
            // handle response
            print("[INFO] Status code from Telegram API:", response.status.code)
        } else {
            // handle remote error
            print("[ERROR] Async request failed:", response.status.description)
        }

    }
}
