import Foundation
import XCTest
@testable import Infuse

final class InfuseTests: XCTestCase {

	// *************************************************
	// MARK: - Internal Resources
	// *************************************************

	private lazy var sut: Infuse = {
		return Infuse()
	}()

	private class MyClass: Equatable {
		let name = "MyClass"

		static func == (lhs: InfuseTests.MyClass, rhs: InfuseTests.MyClass) -> Bool {
			return lhs.name == rhs.name
		}
	}
	private struct MyStruct { let name = "MyStruct" }

	// *************************************************
	// MARK: - SetUp and TearDown
	// *************************************************

	override func setUpWithError() throws {
		sut.reset()
		XCTAssertEqual(sut.registeredCount, 0)

		try sut.register { MyClass() }
		XCTAssertEqual(sut.registeredCount, 1)

		try sut.register { MyStruct() }
		XCTAssertEqual(sut.registeredCount, 2)
	}

	override func tearDownWithError() throws {
		sut.reset()
	}

	// *************************************************
	// MARK: - Tests
	// *************************************************

	func test_registerAndResolveClass() throws {
		XCTAssertEqual(sut.registeredCount, 2)

		let first = try sut.resolve(MyClass.self)
		XCTAssertEqual(sut.registeredCount, 2)

		let second = try sut.resolve(MyClass.self)
		XCTAssertEqual(sut.registeredCount, 2)

		// are different instances but with the same type
		XCTAssert(first !== second)
		XCTAssert(first == second)
	}

	func test_registerAndResolveStruct() throws {
		XCTAssertEqual(sut.registeredCount, 2)

		var first = try sut.resolve(MyStruct.self)
		let firstMemoryAddress = MemoryAddress(of: &first)
		XCTAssertEqual(sut.registeredCount, 2)

		var second = try sut.resolve(MyStruct.self)
		let secondMemoryAddress = MemoryAddress(of: &second)
		XCTAssertEqual(sut.registeredCount, 2)

		XCTAssert(firstMemoryAddress != secondMemoryAddress) // are differents (value type)
	}

	func test_registerSameTypeTwice() throws {
		XCTAssertEqual(sut.registeredCount, 2)

		XCTAssertThrowsError(try sut.register { return MyClass() }) { error in
			XCTAssertEqual(
				// swiftlint:disable:next force_cast
				error as! InfuseError,
				InfuseError.duplicatedDependency(forType: String(describing: MyClass.self))
			)
		}
	}

	func test_resolveUnregisteredType() async throws {
		class MySecondClass { let name = "MySecondClass" }

		XCTAssertEqual(sut.registeredCount, 2)

		XCTAssertThrowsError(try sut.resolve(MySecondClass.self)) { error in
			XCTAssertEqual(
				// swiftlint:disable:next force_cast
				error as! InfuseError,
				InfuseError.dependencyNotFound(forType: String(describing: MySecondClass.self))
			)
		}
	}
}
