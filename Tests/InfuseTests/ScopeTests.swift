import Foundation
import XCTest
@testable import Infuse

final class ScopeTests: XCTestCase {

	// *************************************************
	// MARK: - Internal Resources
	// *************************************************

	private class MyClass: Equatable {
		let name: String

		init(name: String) { self.name = name }

		static func == (lhs: MyClass, rhs: MyClass) -> Bool {
			return lhs.name == rhs.name
		}
	}

	private struct MyStruct: Equatable { let name: String }

	private enum MyEnum: Equatable { case name(String) }

	// *************************************************
	// MARK: - Tests || Default Scope
	// *************************************************

	func test_default_scope_should_register_different_types_of_dependencies() throws {
		let sut = DefaultScope()
		XCTAssertEqual(sut.registeredCount, 0)

		try sut.register { MyClass(name: "name") }
		XCTAssertEqual(sut.registeredCount, 1)

		try sut.register { MyStruct(name: "name") }
		XCTAssertEqual(sut.registeredCount, 2)

		try sut.register { MyEnum.name("name") }
		XCTAssertEqual(sut.registeredCount, 3)
	}

	func test_default_scope_should_register_and_resolve_class() throws {
		let sut = DefaultScope()
		XCTAssertEqual(sut.registeredCount, 0)

		try sut.register { MyClass(name: "name") }
		XCTAssertEqual(sut.registeredCount, 1)

		let first = try sut.resolve(MyClass.self)
		let second = try sut.resolve(MyClass.self)

		// are different instances but with the same type
		XCTAssert(first !== second)
		XCTAssert(first == second)
	}

	func test_default_scope_should_register_and_resolve_struct() throws {
		let sut = DefaultScope()
		XCTAssertEqual(sut.registeredCount, 0)

		try sut.register { MyStruct(name: "name") }
		XCTAssertEqual(sut.registeredCount, 1)

		var first = try sut.resolve(MyStruct.self)
		let firstMemoryAddress = MemoryAddress(of: &first)

		var second = try sut.resolve(MyStruct.self)
		let secondMemoryAddress = MemoryAddress(of: &second)

		XCTAssert(firstMemoryAddress != secondMemoryAddress) // are differents (value type)
		XCTAssert(first == second)
	}

	func test_default_scope_should_register_and_resolve_enum() throws {
		let sut = DefaultScope()
		XCTAssertEqual(sut.registeredCount, 0)

		try sut.register { MyEnum.name("name") }
		XCTAssertEqual(sut.registeredCount, 1)

		let first = try sut.resolve(MyEnum.self)
		let second = try sut.resolve(MyEnum.self)

		XCTAssert(first == second) // are the same enum `case`
	}

	func test_default_scope_should_throw_duplicated_dependency_error() throws {
		let sut = DefaultScope()
		XCTAssertEqual(sut.registeredCount, 0)

		try sut.register { MyClass.self }
		XCTAssertEqual(sut.registeredCount, 1)

		XCTAssertThrowsError(try sut.resolve(MyClass.self)) { error in
			XCTAssertEqual(
				// swiftlint:disable:next force_cast
				error as! InfuseError,
				InfuseError.dependencyNotFound(forType: String(describing: MyClass.self))
			)
		}
	}

	func test_default_scope_should_throw_dependency_not_found_error() async throws {
		class MyOtherClass { let name = "MyOtherClass" }

		let sut = DefaultScope()
		XCTAssertEqual(sut.registeredCount, 0)

		try sut.register { MyClass.self }
		XCTAssertEqual(sut.registeredCount, 1)

		XCTAssertThrowsError(try sut.resolve(MyOtherClass.self)) { error in
			XCTAssertEqual(
				// swiftlint:disable:next force_cast
				error as! InfuseError,
				InfuseError.dependencyNotFound(forType: String(describing: MyOtherClass.self))
			)
		}
	}

	// *************************************************
	// MARK: - Tests || Shared Scope
	// *************************************************

	func test_shared_scope_should_register_different_types_of_dependencies() throws {
		let sut = SharedScope()
		XCTAssertEqual(sut.registeredCount, 0)
		XCTAssertEqual(sut.cachedCount, 0)

		try sut.register { MyClass(name: "name") }
		XCTAssertEqual(sut.registeredCount, 1)
		XCTAssertEqual(sut.cachedCount, 0)

		try sut.register { MyStruct(name: "name") }
		XCTAssertEqual(sut.registeredCount, 2)
		XCTAssertEqual(sut.cachedCount, 0)

		try sut.register { MyEnum.name("name") }
		XCTAssertEqual(sut.registeredCount, 3)
		XCTAssertEqual(sut.cachedCount, 0)
	}

	func test_shared_scope_should_register_and_resolve_class() throws {
		let expected = MyClass(name: "name")

		let sut = SharedScope()
		XCTAssertEqual(sut.registeredCount, 0)
		XCTAssertEqual(sut.cachedCount, 0)

		try sut.register { expected }
		XCTAssertEqual(sut.registeredCount, 1)
		XCTAssertEqual(sut.cachedCount, 0)

		let dependency = try sut.resolve(MyClass.self)
		XCTAssertEqual(sut.cachedCount, 1)

		// are different instances but with the same type
		XCTAssert(dependency === expected)
	}

	func test_shared_scope_should_register_and_resolve_struct() throws {
		var expected = MyStruct(name: "name")
		let expectedMemoryAddress = MemoryAddress(of: &expected)

		let sut = SharedScope()
		XCTAssertEqual(sut.registeredCount, 0)
		XCTAssertEqual(sut.cachedCount, 0)

		try sut.register { expected }
		XCTAssertEqual(sut.registeredCount, 1)
		XCTAssertEqual(sut.cachedCount, 0)

		var dependency = try sut.resolve(MyStruct.self)
		XCTAssertEqual(sut.cachedCount, 1)
		let dependencyMemoryAddress = MemoryAddress(of: &dependency)

		XCTAssert(dependencyMemoryAddress != expectedMemoryAddress) // are differents (value type)
		XCTAssert(dependency == expected)
	}

	func test_shared_scope_should_register_and_resolve_enum() throws {
		let expected = MyEnum.name("name")

		let sut = SharedScope()
		XCTAssertEqual(sut.registeredCount, 0)
		XCTAssertEqual(sut.cachedCount, 0)

		try sut.register { expected }
		XCTAssertEqual(sut.registeredCount, 1)
		XCTAssertEqual(sut.cachedCount, 0)

		let dependency = try sut.resolve(MyEnum.self)
		XCTAssertEqual(sut.cachedCount, 1)

		XCTAssert(dependency == expected) // are the same enum `case`
	}

	func test_shared_scope_should_throw_duplicated_dependency_error() throws {
		let sut = SharedScope()
		XCTAssertEqual(sut.registeredCount, 0)
		XCTAssertEqual(sut.cachedCount, 0)

		try sut.register { MyClass.self }
		XCTAssertEqual(sut.registeredCount, 1)
		XCTAssertEqual(sut.cachedCount, 0)

		XCTAssertThrowsError(try sut.resolve(MyClass.self)) { error in
			XCTAssertEqual(
				// swiftlint:disable:next force_cast
				error as! InfuseError,
				InfuseError.dependencyNotFound(forType: String(describing: MyClass.self))
			)
		}
	}

	func test_shared_scope_should_throw_dependency_not_found_error() async throws {
		class MyOtherClass { let name = "MyOtherClass" }

		let sut = SharedScope()
		XCTAssertEqual(sut.registeredCount, 0)
		XCTAssertEqual(sut.cachedCount, 0)

		try sut.register { MyClass.self }
		XCTAssertEqual(sut.registeredCount, 1)
		XCTAssertEqual(sut.cachedCount, 0)

		XCTAssertThrowsError(try sut.resolve(MyOtherClass.self)) { error in
			XCTAssertEqual(
				// swiftlint:disable:next force_cast
				error as! InfuseError,
				InfuseError.dependencyNotFound(forType: String(describing: MyOtherClass.self))
			)
		}
	}
}
