import Vapor

private struct Constants {
	static let abcTVIPAddress = "192.168.1.61"
	static let abcStartHour = 7
	static let abcEndHour = 9
}

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
	let abcTV = AmazonFireTV(ipAddress: Constants.abcTVIPAddress)
    let calendar = Calendar.current
	let now = Date()
	
	guard let abcStartDate = calendar.nextDate(after: now, matching: DateComponents(hour: Constants.abcStartHour), matchingPolicy: .strict) else { return }
	let abcStartDelay = Int(abcStartDate.timeIntervalSince(now))
	app.eventLoop.scheduleRepeatedTask(
		initialDelay: .seconds(abcStartDelay),
		delay: .hours(24)) { task -> EventLoopFuture<Void> in
		return abcTV.connect(app.eventLoop)
			.then { abcTV.launch(.abc, eventLoop: app.eventLoop) }
			.then { abcTV.disconnect(app.eventLoop) }
	}
	
	guard let abcEndDate = calendar.nextDate(after: now, matching: DateComponents(hour: Constants.abcEndHour), matchingPolicy: .strict) else { return }
	let abcEndDelay = Int(abcEndDate.timeIntervalSince(now))
	app.eventLoop.scheduleRepeatedTask(
		initialDelay: .seconds(abcEndDelay),
		delay: .hours(24)) { task -> EventLoopFuture<Void> in
			return abcTV.connect(app.eventLoop)
				.then { abcTV.launch(.screenCloud, eventLoop: app.eventLoop) }
				.then { abcTV.disconnect(app.eventLoop) }
	}
}
