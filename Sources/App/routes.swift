import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
	router.put("launch_app") { req -> Future<HTTPStatus> in
		return try req.content.decode(LaunchAppContent.self)
			.thenThrowing { content in
				let tv = AmazonFireTV(ipAddress: content.ipAddress)
				guard let app = AmazonFireTVApp(rawValue: content.appName)
					else { throw LaunchAppError.badAppName }
				return tv.connect(req.eventLoop)
					.then { tv.launch(app, eventLoop: req.eventLoop) }
					.then { tv.disconnect(req.eventLoop) }
					.map { return .ok }
			}.then { return $0 }
	}
}

private struct LaunchAppContent: Content {
	var ipAddress: String
	var appName: String
	
	enum CodingKeys: String, CodingKey {
		case ipAddress = "ip_address"
		case appName = "app_name"
	}
}

enum LaunchAppError: String, Error { case badAppName }

extension LaunchAppError: Debuggable {
	var identifier: String { return rawValue }
	
	var reason: String {
		switch self {
		case .badAppName: return "Must specify an available app name."
		}
	}
}
