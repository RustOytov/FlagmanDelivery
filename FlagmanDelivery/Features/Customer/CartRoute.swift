import Foundation

enum CartRoute: Hashable {
    case checkout
    case success(orderId: String)
}
