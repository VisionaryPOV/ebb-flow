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

    private static var projectYAML: String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("project.yml")
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private static func targetBlock(named target: String, in yaml: String) -> String? {
        guard let range = yaml.range(of: "  \(target):") else { return nil }
        let remainder = yaml[range.lowerBound...]
        let lines = remainder.split(separator: "\n", omittingEmptySubsequences: false)
        var collected: [String] = []
        for (index, line) in lines.enumerated() {
            if index > 0, line.hasPrefix("  "), !line.hasPrefix("    "), !line.hasPrefix("  \(target):") {
                break
            }
            collected.append(String(line))
        }
        return collected.joined(separator: "\n")
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

    @Test func sharedConsumersDeclareAppGroupEntitlementsInProjectYAML() {
        let yaml = Self.projectYAML
        #expect(!yaml.isEmpty)

        let sharedConsumers = ["EbbFlow", "EbbFlowWidgets", "EbbFlowWatch", "EbbFlowWatchWidgets"]
        for target in sharedConsumers {
            let block = Self.targetBlock(named: target, in: yaml)
            let section = block ?? ""
            #expect(section.contains("- path: Shared"), "Expected \(target) to include Shared sources")
            #expect(
                section.contains("com.apple.security.application-groups"),
                "Expected \(target) to declare application-groups entitlements"
            )
            #expect(
                section.contains("group.com.ebbflow.shared"),
                "Expected \(target) to use group.com.ebbflow.shared"
            )
        }
    }
}