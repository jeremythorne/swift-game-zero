import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(hello_sdlTests.allTests),
    ]
}
#endif
