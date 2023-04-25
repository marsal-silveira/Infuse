import Foundation

///
/// `Infuse` is a lightweigth and simple `Dependency Injection` framework.
///	It's actually an implementation of the `Service Locator` pattern, based on a simple concept
///	of registering and consuming dependencies/services to avoid a strong coupling between the project components.
///
public final class Infuse {

	// TODO: Check this `lock` approach
	private let lock = NSRecursiveLock()

	private var scopes: [String: ScopeProtocol] = [:]

	// we need this to make its initializer accessible outside
	public init() { }

	@discardableResult
	public func register<T>(
		scope: Scope = Scope.default,
		_ type: T.Type = T.self,
		_ factory: @escaping () throws -> T
	) throws -> Infuse {

		lock.lock()
		defer { lock.unlock()}

		if let scope = scopes[scope.id] {
			try scope.register(type, factory)
		} else {
			let newScope = Scope.newInstance(scope)
			try newScope.register(type, factory)
			scopes[scope.id] = newScope
		}

		return self
	}

	public func resolve<T>(_ type: T.Type) throws -> T {
		lock.lock()
		defer { lock.unlock()}

		var dependency: T?
		for scope in scopes.values {
			dependency = try? scope.resolve(type)
			// if found a dependency, exit the loop
			if dependency != nil { break }
		}
		guard let dependency = dependency else {
			let key = String(describing: type)
			throw InfuseError.dependencyNotFound(forType: key)
		}
		return dependency
	}

	func reset() {
		lock.lock()
		defer { lock.unlock()}

		for scope in scopes.values {
			scope.reset()
		}
	}
}

/// These are for testing purpose
internal extension Infuse {
//	var registeredCount: Int { factories.count }
	// TODO: Check this...
	var registeredCount: Int { -1 }
}
