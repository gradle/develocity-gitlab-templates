#!/bin/bash

mkdir -p build

# Replace the 'BuildScanCollector' implementation in the reference init-script,
# and indent the init-script for inclusion in the 'develocity-gradle.yml' file.
sed -e '/class BuildScanCollector {}/{
    r src/gradle/init-scripts/build-scan-collector.groovy
    d
}' src/gradle/init-scripts/develocity-injection.init.gradle > build/develocity-injection-combined.init.gradle

# Indent init script for inclusion in the 'develocity-gradle.yml' file.
sed -e 's/^/      /' build/develocity-injection-combined.init.gradle > build/develocity-injection-indented.init.gradle

# Construct the 'develocity-gradle.yml' file from the template and the init-script contents.
sed -e '/<<DEVELOCITY_INJECTION_INIT_GRADLE>>/{
    r build/develocity-injection-indented.init.gradle
    d
}' src/gradle/develocity-gradle.template.yml > develocity-gradle.yml
