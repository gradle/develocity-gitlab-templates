// Custom implementation of BuildScanCollector for GitLab integration
class BuildScanCollector {
  def captureBuildScanLink(String buildScanLink) {
    if (System.getenv("BUILD_SCAN_REPORT_PATH")) {
      def reportFile = new File(System.getenv("BUILD_SCAN_REPORT_PATH"))
      def report
      // This might have been created by a previous Gradle invocation in the same GitLab job
      // Note that we do not handle parallel Gradle scripts invocation, which should be a very edge case in context of a GitLab job
      if (reportFile.exists()) {
        report = new groovy.json.JsonSlurper().parseText(reportFile.text) as Report
      } else {
        report = new Report()
      }
      report.addLink(buildScanLink)
      def generator = new groovy.json.JsonGenerator.Options()
        .excludeFieldsByName('contentHash', 'originalClassName')
        .build()
      reportFile.text = generator.toJson(report)
    }
  }
}

class Report {
  List<Link> build_scans = []

  void addLink(String url) {
    build_scans << new Link(url)
  }
}

class Link {
  Map external_link

  Link(String url) {
    external_link = [ 'label': url, 'url': url ]
  }
}
