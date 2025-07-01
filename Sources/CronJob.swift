import Vapor
import VaporCron

struct UpdateDomainsJob: VaporCronSchedulable {
    static var expression: String { "* * * * 0" } // hourly

    static func task(on application: Application) -> EventLoopFuture<Void> {
        return application.eventLoopGroup.future().always { _ in
            print("[INFO] UpdateDomainsJob fired, updating domains...")

            Task { @MainActor in
                let appState = AppState.shared

                await updateDomains()

                for domain in appState.domains.values {
                    Notification().checkForNotification(domain: domain)
                }
            }
        }
    }
}
