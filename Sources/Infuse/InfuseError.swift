import Foundation

public enum InfuseError:
	LocalizedError,
	Equatable,
	CustomStringConvertible,
	CustomDebugStringConvertible {

	case duplicatedDependency(forType: String)
	case dependencyNotFound(forType: String)

	public var description: String {
		switch self {
		case .duplicatedDependency(let type): return "Duplicated dependency found for type `\(type)`."
		case .dependencyNotFound(let type): return "Dependency not found for type `\(type)`."
		}
	}

	public var errorDescription: String? { return description }
	public var localizedDescription: String { return description }
	public var debugDescription: String { return description }
}
