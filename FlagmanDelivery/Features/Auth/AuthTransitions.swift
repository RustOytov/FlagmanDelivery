import SwiftUI

enum AuthTransitions {
    static let push: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )

    static let pop: AnyTransition = .asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )
}
