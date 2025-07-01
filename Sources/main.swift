import Foundation
import Network

import Vapor

let app = try await Application.make(.detect())

@MainActor
func main() async throws {
    let appState = AppState.shared

    let envDomains = ProcessInfo.processInfo.environment["DOMAINS"]?.split(separator: ",").map(String.init) ?? []
    let envTelegramNotification = ProcessInfo.processInfo.environment["TELEGRAM_NOTIFICATION"]?.lowercased() ?? "false"

    guard !envDomains.isEmpty else {
        print("[ERROR] No domains provided. Set the DOMAINS environment variable as comma-separated values.")
        return
    }

    for domain in envDomains {
        guard !domain.isEmpty else {
            print("[WARN] Skipping empty domain entry.")
            continue
        }

        let domainName = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        appState.domains[domainName] = DomainWatched(domain: domainName, expiryDate: nil)
    }

    if envTelegramNotification == "true" {
        guard let telegramChatId = ProcessInfo.processInfo.environment["TELEGRAM_CHAT_ID"] else {
            print("[ERROR] Telegram notification enabled but TELEGRAM_CHAT_ID environment variable not set")
            return
        }

        guard let telegramBotToken = ProcessInfo.processInfo.environment["TELEGRAM_BOT_TOKEN"] else {
            print("[ERROR] Telegram notification enabled but TELEGRAM_BOT_TOKEN environment variable not set")
            return
        }

        appState.telegramChatId = telegramChatId
        appState.telegramBotToken = telegramBotToken
        appState.telegramNotification = true

        print("[INFO] Telegram notifications are enabled.")
    } else {
        appState.telegramNotification = false
        print("[INFO] Telegram notifications are disabled.")
    }

    // Initial domain update with notification trigger
    print("[INFO] Starting domain expiry watcher...")
    await updateDomains()

    for domain in appState.domains.values {
        Notification().checkForNotification(domain: domain)
    }

    // Vapor
    try app.cron.schedule(UpdateDomainsJob.self)
    try await app.execute()
}

@MainActor
func updateDomains() async {
    print("[INFO] Updating domains...")
    let appState = AppState.shared

    for var domain in appState.domains.values {
        do {
            let expiryDate = try await WhoisUtils.getExpiryDate(domain: domain.domain)
            if expiryDate != "?" {
                print("[INFO] Domain: \(domain.domain), Expiry Date: \(expiryDate)")

                let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: false).parse(expiryDate)
                let dateFracSeconds = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(expiryDate)

                if let date = date {
                    domain.expiryDate = date
                    appState.domains[domain.domain] = domain
                } else if let dateFracSeconds = dateFracSeconds {
                    domain.expiryDate = dateFracSeconds
                    appState.domains[domain.domain] = domain
                } else {
                    print("[WARN] Invalid date format for domain: \(domain.domain)")
                }
            } else {
                print("[WARN] Failed to retrieve expiry date for domain: \(domain.domain)")
            }
        } catch {
            print("[ERROR] Error retrieving expiry date for domain \(domain.domain): \(error)")
        }
    }
}

try await main()