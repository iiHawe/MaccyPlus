import SwiftUI

private struct HoverSelectionModifier: ViewModifier {
  @Environment(AppState.self) private var appState
  var id: UUID

  func body(content: Content) -> some View {
    content.onHover { hovering in
      if hovering {
        // Preserve the existing selection while moving to a Command-click target.
        guard !appState.multiSelectionEnabled || !NSEvent.modifierFlags.contains(.command) else { return }
        if !appState.navigator.isKeyboardNavigating && !appState.navigator.isMultiSelectInProgress {
          appState.navigator.selectWithoutScrolling(id: id)
        } else {
          appState.navigator.hoverSelectionWhileKeyboardNavigating = id
        }
      }
    }
  }
}

extension View {
  func hoverSelectionId(_ id: UUID) -> some View {
    modifier(HoverSelectionModifier(id: id))
  }
}
