import Sparkle
import Combine

/// Manages Sparkle auto-updates.
/// Checks once a day in background and publishes update availability.
final class UpdaterManager: NSObject, ObservableObject, SPUUpdaterDelegate {
    static let shared = UpdaterManager()

    private(set) var updaterController: SPUStandardUpdaterController!

    @Published var canCheckForUpdates = false
    @Published var updateAvailable = false

    private override init() {
        super.init()

        // Now that self is available, create controller with self as delegate
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: self,
            userDriverDelegate: nil
        )

        // Auto-check every 24 hours
        updaterController.updater.automaticallyChecksForUpdates = true
        updaterController.updater.updateCheckInterval = 24 * 60 * 60

        // Start the updater
        do {
            try updaterController.updater.start()
        } catch {
            print("[UpdaterManager] Failed to start: \(error)")
        }

        // Observe canCheckForUpdates
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    // MARK: - SPUUpdaterDelegate

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        DispatchQueue.main.async {
            self.updateAvailable = true
        }
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: any Error) {
        DispatchQueue.main.async {
            self.updateAvailable = false
        }
    }
}
