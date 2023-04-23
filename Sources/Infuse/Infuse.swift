import Foundation

///
/// `Infuse` is a lightweigth and simple `Dependency Injection` framework.
///	It's actually an implementation of the `Service Locator` pattern, based on a simple concept
///	of registering and consuming dependencies/services to avoid a strong coupling between the project components.
///
public final class Infuse {

	private class Factory {
		private let factory: () throws -> Any

		init(_ factory: @escaping () throws -> Any) {
			self.factory = factory
		}

		func callAsFunction<T>() throws -> T {
			return try resolve()
		}

		func resolve<T>() throws -> T {
			guard let instance = try factory() as? T else {
				throw InfuseError.dependencyNotFound(forType: String(describing: T.self))
			}
			return instance
		}
	}

	private let lock = NSRecursiveLock()

	private var factories: [String: Factory] = [:]

	// we need this to make its initializer accessible outside
	public init() { }

	@discardableResult
	public func register<T>(_ type: T.Type = T.self, _ factory: @escaping () throws -> T) throws -> Infuse {
		lock.lock()
		defer { lock.unlock()}

		let key = String(describing: type)
		guard factories.contains(where: { $0.key == key }) == false else {
			throw InfuseError.duplicatedDependency(forType: key)
		}
		factories[key] = Factory(factory)

		return self
	}

	public func resolve<T>(_ type: T.Type) throws -> T {
		lock.lock()
		defer { lock.unlock()}

		let key = String(describing: type)
		guard let factory = factories[key] else {
			throw InfuseError.dependencyNotFound(forType: key)
		}
		return try factory() as T
	}

	 func reset() {
		lock.lock()
		defer { lock.unlock()}

		factories.removeAll()
	}
}

/// These are for testing purpose
internal extension Infuse {
	var registeredCount: Int { factories.count }
}
