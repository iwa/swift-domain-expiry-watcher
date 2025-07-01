class AppState {
    @MainActor static let shared = AppState()

    var domains: [String: DomainWatched] = [:]
    var telegramNotification: Bool = false
    var telegramChatId: String = ""
    var telegramBotToken: String = ""

    private init() {}
}