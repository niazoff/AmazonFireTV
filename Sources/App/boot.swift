import Vapor

struct Constants {
	static let bootDataURL = "https://api.myjson.com/bins/8u018"
}

/// Called after application has initialized.
public func boot(_ app: Application) throws {
	try app.client().get(Constants.bootDataURL).flatMap { res in
		return try res.content.decode(BootData.self).do { bootData in
			bootData.tvIpAddresses.map(AmazonFireTV.init).forEach { tv in bootData.scheduledAppLaunches.forEach { setupLaunch($0.app, on: tv, atHour: $0.hour, minute: $0.minute, in: app.eventLoop) } }
		}
	}.catch { print($0) }
}

private func setupLaunch(_ app: AmazonFireTVApp, on tv: AmazonFireTV, atHour hour: Int, minute: Int? = nil, in eventLoop: EventLoop) {
	let calendar = Calendar.current
	let now = Date()
	guard let appLaunchDate = calendar.nextDate(after: now, matching: DateComponents(hour: hour, minute: minute), matchingPolicy: .strict) else { return }
	let appLaunchDelay = Int(appLaunchDate.timeIntervalSince(now))
	eventLoop.scheduleRepeatedTask(
		initialDelay: .seconds(appLaunchDelay),
		delay: .hours(24)) { task -> EventLoopFuture<Void> in
			return tv.connect(eventLoop)
				.then { tv.launch(app, eventLoop: eventLoop) }
				.then { tv.disconnect(eventLoop) }
	}
}

struct BootData: Content {
	let tvIpAddresses: [String]
	let scheduledAppLaunches: [ScheduledAppLaunch]
	
	struct ScheduledAppLaunch: Codable {
		let app: AmazonFireTVApp
		let hour: Int
		let minute: Int?
	}
}
