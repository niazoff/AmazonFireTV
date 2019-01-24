import Vapor

/// Register application's routes.
public func routes(_ router: Router) throws {
	router.put(String.parameter, "app") { req -> Future<HTTPStatus> in
		return try req.content.decode(AppLaunch.self)
			.thenThrowing { launch in
				let ipAddress = try req.parameters.next(String.self)
				let tv = AmazonFireTV(ipAddress: ipAddress)
				return tv.connect(req.eventLoop)
					.then { tv.launch(launch.app, eventLoop: req.eventLoop) }
					.then { tv.disconnect(req.eventLoop) }
					.map { return .ok }
			}.then { return $0 }
	}
}

private struct AppLaunch: Content {
	var app: AmazonFireTVApp
}
