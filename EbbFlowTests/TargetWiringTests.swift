import Foundation
import Testing

struct TargetWiringTests {
    private static var projectContents: String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("EbbFlow.xcodeproj/project.pbxproj")
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    @Test func ebbFlowEmbedsIOSWidgetsExtension() {
        let pbxproj = Self.projectContents
        #expect(!pbxproj.isEmpty)
        #expect(pbxproj.contains("EbbFlowWidgets.appex in Embed"))
        #expect(pbxproj.contains("PBXCopyFilesBuildPhase"))
    }

    @Test func ebbFlowWatchEmbedsWatchWidgetsExtension() {
        let pbxproj = Self.projectContents
        #expect(!pbxproj.isEmpty)

        #expect(
            pbxproj.contains("Embed App Extensions")
                || pbxproj.contains("Embed Foundation Extensions")
        )
        #expect(pbxproj.contains("EbbFlowWatchWidgets.appex in Embed"))
        #expect(pbxproj.contains("PBXCopyFilesBuildPhase"))
    }

    @Test func mainAndWatchTargetsDeclareWidgetDependencies() {
        let pbxproj = Self.projectContents
        #expect(pbxproj.contains("EbbFlowWidgets"))
        #expect(pbxproj.contains("EbbFlowWatchWidgets"))
        #expect(pbxproj.contains("EbbFlowWatch"))
    }
}