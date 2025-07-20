import SwiftUI

struct ModalConfiguration: ViewModifier {

    func body(content: Content) -> some View {
        content
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(24)
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium])
    }
}
