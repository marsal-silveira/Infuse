import Foundation

// TODO: Doc
public enum ScopeStrategy {
	case `default` // each request create a new instance
	case shared // all requests will share the same instance created by the first request (i.e. singleton strategy)
}

// TODO: Doc
public enum Scope {
	case `default` // the `default` scope will uses the `default` strategy too
	case shared // the `shared` scope will uses the `shared` strategy too
	case custom(id: String, strategy: ScopeStrategy) // here we can define a new scope using some strategy

	var id: String {
		switch self {
		case .`default`: return ".default"
		case .shared: return ".shared"
		case .custom(let id, let strategy): return ".custom(id: \(id), strategy: \(strategy)"
		}
	}
}

// TODO: Doc
internal protocol ScopeProtocol {
	func register<T>(_ type: T.Type, _ factory: @escaping () throws -> T) throws
	func resolve<T>(_ type: T.Type) throws -> T
	func reset()
}

// TODO: Doc
internal extension ScopeProtocol {
	func register<T>(_ type: T.Type = T.self, _ factory: @escaping () throws -> T) throws {
		try register(type, factory)
	}
}


// TODO: Doc
internal final class DefaultScope: ScopeProtocol {
	private var factories: [String: Factory] = [:]

	func register<T>(_ type: T.Type, _ factory: @escaping () throws -> T) throws {
		let key = String(describing: type)
		guard factories[key] == nil else {
			throw InfuseError.duplicatedDependency(forType: key)
		}
		factories[key] = Factory(factory)
	}

	func resolve<T>(_ type: T.Type) throws -> T {
		let key = String(describing: type)
		guard let factory = factories[key] else {
			throw InfuseError.dependencyNotFound(forType: key)
		}

		return try factory() as T
	}

	func reset() {
		factories.removeAll()
	}

	// for test purpose
	var registeredCount: Int { factories.count }
}

// TODO: Doc
internal final class SharedScope: ScopeProtocol {
	private var factories: [String: Factory] = [:]
	private var cache: [String: Any] = [:]

	func register<T>(_ type: T.Type, _ factory: @escaping () throws -> T) throws {
		let key = String(describing: type)
		guard factories[key] == nil else {
			throw InfuseError.duplicatedDependency(forType: key)
		}
		factories[key] = Factory(factory)
	}

	func resolve<T>(_ type: T.Type) throws -> T {
		let key = String(describing: type)

		if let dependecy = cache[key] as? T {
			return dependecy
		} else {
			guard let factory = factories[key] else {
				throw InfuseError.dependencyNotFound(forType: key)
			}

			let dependency = try factory() as T
			cache[key] = dependency

			return dependency
		}
	}

	func reset() {
		factories.removeAll()
		cache.removeAll()
	}

	// for test purpose
	var registeredCount: Int { factories.count }
	var cachedCount: Int { cache.count }
}

// TODO: Doc
internal extension Scope {
	static func newInstance(_ scope: Scope) -> ScopeProtocol {
		switch scope {
		case .`default`:
			return DefaultScope()
		case .shared:
			return SharedScope()
		case .custom(_, let strategy):
			switch strategy {
			case .`default`:
				return DefaultScope()
			case .shared:
				 return SharedScope()
			}
		}
	}
}
