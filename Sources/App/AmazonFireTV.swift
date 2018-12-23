import Vapor

enum AmazonFireTVApp: String {
	case screenCloud = "screen_cloud"
	case abc
	
	var packageName: String {
		switch self {
		case .screenCloud: return "io.screencloud.player"
		case .abc: return "com.disney.datg.videoplatforms.android.amazon.kindle.abc"
		}
	}
}

struct AmazonFireTV {
	let ipAddress: String
	
	struct Constants {
		static let adbPath = "/usr/local/bin/adb"
	}
	
	func connect(_ eventLoop: EventLoop) -> Future<Void> {
		guard #available(macOS 10.13, *)
			else { return eventLoop.newFailedFuture(error: AmazonFireTVError.notAvailableOnThisVersion) }
		return shell(Constants.adbPath, "connect", ipAddress, eventLoop: eventLoop)
	}
	
	func disconnect(_ eventLoop: EventLoop) -> Future<Void> {
		guard #available(macOS 10.13, *)
			else { return eventLoop.newFailedFuture(error: AmazonFireTVError.notAvailableOnThisVersion) }
		return shell(Constants.adbPath, "disconnect", ipAddress, eventLoop: eventLoop)
	}
	
	func launch(_ app: AmazonFireTVApp, eventLoop: EventLoop) -> Future<Void> {
		guard #available(macOS 10.13, *)
			else { return eventLoop.newFailedFuture(error: AmazonFireTVError.notAvailableOnThisVersion) }
		return shell(Constants.adbPath, "shell", "monkey", "--pct-syskeys", "0", "-p", app.packageName, "1", eventLoop: eventLoop)
	}
}

@available(macOS 10.13, *)
private func shell(_ args: String..., eventLoop: EventLoop) -> Future<Void> {
	let promise = eventLoop.newPromise(Void.self)
	let process = Process()
	guard let path = args.first
		else { promise.fail(error: ShellError.mustProvideLaunchPath); return promise.futureResult }
	process.executableURL = URL(fileURLWithPath: path)
	process.arguments = Array(args.dropFirst())
	do { try process.run() } catch { promise.fail(error: error) }
	process.terminationHandler = {
		switch TerminationStatus($0.terminationStatus) {
		case .succeeded: promise.succeed()
		case .failed(let error): promise.fail(error: error)
		}
	}
	return promise.futureResult
}

private enum AmazonFireTVError: Error { case notAvailableOnThisVersion }

private enum ShellError: Error { case mustProvideLaunchPath }

private enum TerminationStatus {
	case succeeded
	case failed(TerminationError)
	
	init(_ status: Int32) {
		if status == 0 { self = .succeeded }
		else { self = .failed(.default(status)) }
	}
}

private enum TerminationError: Error { case `default`(Int32) }

extension TerminationError: Debuggable {
	var identifier: String {
		switch self {
		case .default(let status): return String(status)
		}
	}
	
	var reason: String {
		switch self {
		case .default(let status): return "Shell error with status: \(status)"
		}
	}
}
