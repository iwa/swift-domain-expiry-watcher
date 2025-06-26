import Vapor
import VaporCron

struct UpdateDomainsJob: VaporCronSchedulable {
    static var expression: String { "* * * * 0" } // hourly

    static func task(on application: Application) -> EventLoopFuture<Void> {
        return application.eventLoopGroup.future().always { _ in
            print("ComplexJob fired")
            Task {
                await updateDomains()
            }
        }
    }
}
