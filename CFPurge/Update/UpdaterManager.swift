import AppKit
import Foundation

/// Vérifie les GitHub Releases pour une version plus récente et installe
/// le .dmg correspondant en remplaçant le bundle .app une fois l'app fermée.
@MainActor
final class UpdaterManager: ObservableObject {
    private struct GitHubRelease: Decodable {
        struct Asset: Decodable {
            let name: String
            let browserDownloadURL: URL

            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadURL = "browser_download_url"
            }
        }

        let tagName: String
        let htmlUrl: URL
        let assets: [Asset]
        let draft: Bool
        let prerelease: Bool

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlUrl = "html_url"
            case assets
            case draft
            case prerelease
        }
    }

    private static let repo = "Crollin/CFPurge"
    private static let checkInterval: TimeInterval = 12 * 60 * 60
    private static let autoCheckKey = "autoUpdateChecks"
    /// Emplacement canonique : toute mise à jour écrase ce bundle (évite les doublons Launchpad).
    static let canonicalInstallURL = URL(fileURLWithPath: "/Applications/CFPurge.app")

    private static var archSuffix: String {
        #if arch(arm64)
        return "darwin-arm64"
        #else
        return "darwin-x86_64"
        #endif
    }

    @Published private(set) var updateAvailable = false
    @Published private(set) var latestVersion: String?
    @Published private(set) var releaseURL: URL?
    @Published private(set) var isChecking = false
    @Published private(set) var isInstalling = false
    @Published private(set) var installError: String?

    private var timer: Timer?
    private var pendingAssetURL: URL?
    private var autoCheck: Bool

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    init() {
        if UserDefaults.standard.object(forKey: Self.autoCheckKey) == nil {
            autoCheck = true
        } else {
            autoCheck = UserDefaults.standard.bool(forKey: Self.autoCheckKey)
        }

        if autoCheck {
            scheduleAutomaticChecks()
            checkForUpdates()
        }
    }

    var automaticallyChecksForUpdates: Bool {
        get { autoCheck }
        set {
            guard newValue != autoCheck else { return }
            autoCheck = newValue
            UserDefaults.standard.set(newValue, forKey: Self.autoCheckKey)
            if newValue {
                scheduleAutomaticChecks()
                checkForUpdates()
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }

    private var isPackagedApp: Bool {
        Self.isUserInstalledApp(at: Bundle.main.bundleURL)
    }

    /// Ignore les builds Xcode / .build (sinon Launchpad enregistre une « nouvelle » app à chaque compile).
    nonisolated static func isUserInstalledApp(at bundleURL: URL) -> Bool {
        guard bundleURL.pathExtension == "app" else { return false }
        let path = bundleURL.resolvingSymlinksInPath().path
        let blockedMarkers = ["/DerivedData/", "/.build/", "/Index.noindex/"]
        return !blockedMarkers.contains { path.contains($0) }
    }

    func checkForUpdates() {
        guard isPackagedApp else { return }
        guard !isChecking else { return }
        isChecking = true

        Task {
            defer { isChecking = false }
            guard let release = await Self.fetchLatestRelease() else { return }

            let current = currentVersion
            let latest = Self.version(of: release)
            guard Self.isNewer(latest, than: current) else {
                updateAvailable = false
                latestVersion = nil
                releaseURL = nil
                pendingAssetURL = nil
                return
            }

            guard let asset = Self.preferredDownloadAsset(for: release) else { return }

            updateAvailable = true
            latestVersion = latest
            releaseURL = release.htmlUrl
            pendingAssetURL = asset.browserDownloadURL
        }
    }

    func openReleasePage() {
        guard let releaseURL else { return }
        NSWorkspace.shared.open(releaseURL)
    }

    func installUpdate() {
        guard !isInstalling else { return }
        guard isPackagedApp, let assetURL = pendingAssetURL else {
            openReleasePage()
            return
        }

        isInstalling = true
        installError = nil

        Task {
            do {
                let dmgURL = try await Self.download(assetURL)
                // Toujours écraser /Applications/CFPurge.app, même si l'app tourne ailleurs.
                try Self.launchInstallerAndQuit(
                    dmgURL: dmgURL,
                    runningAppURL: Bundle.main.bundleURL,
                    installAppURL: Self.canonicalInstallURL
                )
            } catch {
                isInstalling = false
                installError = "\(error)"
                openReleasePage()
            }
        }
    }

    private func scheduleAutomaticChecks() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Self.checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkForUpdates() }
        }
    }

    private static func fetchLatestRelease() async -> GitHubRelease? {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases?per_page=20") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            let http = response as? HTTPURLResponse,
            http.statusCode == 200,
            let releases = try? JSONDecoder().decode([GitHubRelease].self, from: data)
        else {
            return nil
        }

        return releases
            .filter { !$0.draft && !$0.prerelease }
            .max { lhs, rhs in
                compareVersions(version(of: lhs), version(of: rhs)) == .orderedAscending
            }
    }

    private static func version(of release: GitHubRelease) -> String {
        release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
    }

    private static func preferredDownloadAsset(for release: GitHubRelease) -> GitHubRelease.Asset? {
        let dmgAssets = release.assets.filter { $0.name.hasSuffix(".dmg") }
        let canonicalName = "CFPurge-\(release.tagName).dmg"
        return dmgAssets.first { $0.name == canonicalName }
            ?? dmgAssets.first { $0.name.contains("darwin-universal") }
            ?? dmgAssets.first { $0.name.contains(archSuffix) }
            ?? dmgAssets.first
    }

    nonisolated static func isNewer(_ candidate: String, than current: String) -> Bool {
        compareVersions(candidate, current) == .orderedDescending
    }

    nonisolated static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let (lhsCore, lhsPre) = splitVersion(lhs)
        let (rhsCore, rhsPre) = splitVersion(rhs)
        let coreResult = compareCore(lhsCore, rhsCore)
        guard coreResult == .orderedSame else { return coreResult }

        switch (lhsPre, rhsPre) {
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedDescending
        case (_, nil):
            return .orderedAscending
        case let (lhsId?, rhsId?):
            return comparePrerelease(lhsId, rhsId)
        }
    }

    nonisolated private static func splitVersion(_ version: String) -> (core: [Int], prerelease: String?) {
        let parts = version.split(separator: "-", maxSplits: 1)
        let core = parts[0].split(separator: ".").map { Int($0) ?? 0 }
        let prerelease = parts.count > 1 ? String(parts[1]) : nil
        return (core, prerelease)
    }

    nonisolated private static func compareCore(_ lhs: [Int], _ rhs: [Int]) -> ComparisonResult {
        let count = max(lhs.count, rhs.count)
        for index in 0..<count {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left < right { return .orderedAscending }
            if left > right { return .orderedDescending }
        }
        return .orderedSame
    }

    nonisolated private static func comparePrerelease(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsIds = lhs.split(separator: ".").map(String.init)
        let rhsIds = rhs.split(separator: ".").map(String.init)
        let count = max(lhsIds.count, rhsIds.count)

        for index in 0..<count {
            let left = index < lhsIds.count ? lhsIds[index] : nil
            let right = index < rhsIds.count ? rhsIds[index] : nil

            switch (left, right) {
            case (nil, nil):
                return .orderedSame
            case (nil, _):
                return .orderedAscending
            case (_, nil):
                return .orderedDescending
            case let (left?, right?):
                if let leftNumber = Int(left), let rightNumber = Int(right) {
                    if leftNumber < rightNumber { return .orderedAscending }
                    if leftNumber > rightNumber { return .orderedDescending }
                } else if left != right {
                    return left.localizedStandardCompare(right)
                }
            }
        }

        return .orderedSame
    }

    private static func download(_ assetURL: URL) async throws -> URL {
        let (tempLocation, _) = try await URLSession.shared.download(from: assetURL)
        let dmgURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".dmg")
        try? FileManager.default.removeItem(at: dmgURL)
        try FileManager.default.moveItem(at: tempLocation, to: dmgURL)
        return dmgURL
    }

    private static func launchInstallerAndQuit(
        dmgURL: URL,
        runningAppURL: URL,
        installAppURL: URL
    ) throws {
        let pid = ProcessInfo.processInfo.processIdentifier
        let script = """
        #!/bin/sh
        # $1 = chemin de l'app en cours (peut différer de DEST)
        # $2 = DMG téléchargé
        # $3 = PID à attendre
        # $4 = destination canonique (/Applications/CFPurge.app)
        RUNNING="$1"; DMG="$2"; PID="$3"; DEST="$4"
        SCRIPT="$0"
        LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

        reopen_fallback() {
          if [ -d "$DEST" ]; then
            /usr/bin/open "$DEST"
          elif [ -d "$RUNNING" ]; then
            /usr/bin/open "$RUNNING"
          fi
        }

        while kill -0 "$PID" 2>/dev/null; do sleep 0.3; done

        MNT="$(/usr/bin/mktemp -d)" || { reopen_fallback; /bin/rm -f "$SCRIPT"; exit 1; }
        if ! /usr/bin/hdiutil attach "$DMG" -nobrowse -quiet -mountpoint "$MNT"; then
          /bin/rmdir "$MNT" 2>/dev/null
          /bin/rm -f "$DMG" "$SCRIPT"
          reopen_fallback
          exit 1
        fi

        SRC="$(/usr/bin/find "$MNT" -maxdepth 1 -name '*.app' -print -quit)"
        LAUNCH="$DEST"
        if [ -n "$SRC" ]; then
          /bin/mkdir -p "$(/usr/bin/dirname "$DEST")"
          STAGE="$DEST.update-new"
          /bin/rm -rf "$STAGE"
          if /usr/bin/ditto "$SRC" "$STAGE"; then
            /usr/bin/xattr -cr "$STAGE" 2>/dev/null
            BACKUP="$DEST.update-old"
            /bin/rm -rf "$BACKUP"
            OK=1
            if [ -d "$DEST" ]; then
              /bin/mv "$DEST" "$BACKUP" || OK=0
            fi
            if [ "$OK" = "1" ] && /bin/mv "$STAGE" "$DEST"; then
              /bin/rm -rf "$BACKUP"
              # Supprime l'ancienne copie si l'app ne tournait pas déjà depuis /Applications
              if [ "$RUNNING" != "$DEST" ] && [ -d "$RUNNING" ]; then
                case "$RUNNING" in
                  */DerivedData/*|*/.build/*|*/Index.noindex/*) ;;
                  *) /bin/rm -rf "$RUNNING" ;;
                esac
              fi
              # Nettoie les doublons Finder (« CFPurge 2.app », etc.) dans /Applications
              APPS_DIR="$(/usr/bin/dirname "$DEST")"
              DEST_BASE="$(/usr/bin/basename "$DEST" .app)"
              /usr/bin/find "$APPS_DIR" -maxdepth 1 -name "${DEST_BASE} *.app" -exec /bin/rm -rf {} +
              # Force Launch Services / Launchpad à ne garder que le bundle canonique
              if [ -x "$LSREGISTER" ]; then
                "$LSREGISTER" -f "$DEST" >/dev/null 2>&1 || true
              fi
            else
              if [ -d "$BACKUP" ] && [ ! -d "$DEST" ]; then /bin/mv "$BACKUP" "$DEST"; fi
              LAUNCH="$DEST"
              [ -d "$LAUNCH" ] || LAUNCH="$RUNNING"
            fi
          fi
          /bin/rm -rf "$STAGE"
        fi

        /usr/bin/hdiutil detach "$MNT" -quiet 2>/dev/null || /usr/bin/hdiutil detach "$MNT" -force -quiet 2>/dev/null || true
        /bin/rmdir "$MNT" 2>/dev/null
        /bin/rm -f "$DMG" "$SCRIPT"
        if [ -d "$LAUNCH" ]; then
          /usr/bin/open "$LAUNCH"
        else
          reopen_fallback
        fi
        """

        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cfpurge-update-\(pid)-\(UUID().uuidString).sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            scriptURL.path,
            runningAppURL.path,
            dmgURL.path,
            "\(pid)",
            installAppURL.path,
        ]
        try process.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            NSApp.terminate(nil)
        }
    }
}
