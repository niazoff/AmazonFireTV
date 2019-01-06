import Vapor

let tvIPAddresses = ["192.168.1.61", "192.168.1.34"]

private struct Constants {
	static let abcStartHour = 7
	static let screenCloudStartHour = 9
}

/// Called after application has initialized.
public func boot(_ app: Application) throws {
	let tvs = tvIPAddresses.map(AmazonFireTV.init)
	for tv in tvs {
		setupLaunch(.abc, on: tv, atHour: Constants.abcStartHour, in: app.eventLoop)
		setupLaunch(.screenCloud, on: tv, atHour: Constants.screenCloudStartHour, in: app.eventLoop)
	}
}

private func setupLaunch(_ app: AmazonFireTVApp, on tv: AmazonFireTV, atHour hour: Int, in eventLoop: EventLoop) {
	let calendar = Calendar.current
	let now = Date()
	guard let appLaunchDate = calendar.nextDate(after: now, matching: DateComponents(hour: hour), matchingPolicy: .strict) else { return }
	let appLaunchDelay = Int(appLaunchDate.timeIntervalSince(now))
	eventLoop.scheduleRepeatedTask(
		initialDelay: .seconds(appLaunchDelay),
		delay: .hours(24)) { task -> EventLoopFuture<Void> in
			return tv.connect(eventLoop)
				.then { tv.launch(app, eventLoop: eventLoop) }
				.then { tv.disconnect(eventLoop) }
	}
}
