import Foundation

// TODO: Doc
internal class Factory {
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
