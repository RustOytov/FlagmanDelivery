import XCTest

final class BackendOrderFlowContractTests: XCTestCase {
    func testCustomerOrderIsCreatedAsReadyForCourierFeed() throws {
        let backendFile = "/Users/polaroytov/Desktop/flagmanDelivery/hac.new/api/customers.py"
        let contents = try String(contentsOfFile: backendFile, encoding: .utf8)

        XCTAssertTrue(contents.contains("status=OrderStatus.READY"))
    }

    func testCourierAvailableOrdersIncludesPendingAndReadyOrders() throws {
        let backendFile = "/Users/polaroytov/Desktop/flagmanDelivery/hac.new/api/couriers.py"
        let contents = try String(contentsOfFile: backendFile, encoding: .utf8)

        XCTAssertTrue(contents.contains("_COURIER_FEED_STATUSES"))
        XCTAssertTrue(contents.contains("OrderStatus.PENDING"))
        XCTAssertTrue(contents.contains("OrderStatus.CONFIRMED"))
        XCTAssertTrue(contents.contains("OrderStatus.PREPARING"))
        XCTAssertTrue(contents.contains("OrderStatus.READY"))
    }
}
