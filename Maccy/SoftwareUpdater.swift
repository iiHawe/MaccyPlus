import AppKit

@Observable
class SoftwareUpdater {
  // Upstream Sparkle releases would replace the Maccy+ customizations.
  // Only offer releases built from this fork, with manual installation.
  private let releasesURL = URL(string: "https://github.com/iiHawe/MaccyPlus/releases/latest")!

  func checkForUpdates() {
    NSWorkspace.shared.open(releasesURL)
  }
}
