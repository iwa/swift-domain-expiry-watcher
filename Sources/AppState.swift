class AppState {
    @MainActor static let shared = AppState()

    var domains: [String: DomainWatched] = [:]
    var telegramNotification: Bool = false

    private init() {}
}