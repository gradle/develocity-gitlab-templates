#!/bin/bash

mkdir -p build
# Gradle templates
## Replace the 'BuildScanCollector' implementation in the reference init-script,
## and indent the init-script for inclusion in the 'develocity-gradle.yml' file.
sed -e '/class BuildScanCollector {}/{
    r src/gradle/init-scripts/build-scan-collector.groovy
    d
}' src/gradle/init-scripts/develocity-injection.init.gradle > build/develocity-injection-combined.init.gradle

## Indent init script for inclusion in the 'develocity-gradle.yml' file.
sed -e 's/^/      /' build/develocity-injection-combined.init.gradle > build/develocity-injection-indented.init.gradle

## Construct the 'develocity-gradle.yml' file from the template and the init-script contents.
sed -e '/<<DEVELOCITY_INJECTION_INIT_GRADLE>>/{
    r build/develocity-injection-indented.init.gradle
    d
}' src/gradle/develocity-gradle.template.yml > build/develocity-gradle-without-token.yml

## Add the token script
sed -e '/<<DEVELOCITY_INJECTION_SCRIPT_TOKEN>>/{
    r src/common/token.sh
    d
}' build/develocity-gradle-without-token.yml > develocity-gradle.yml

## Construct wrapper script for the Dockerfile
## Include token script
sed -e '/<<DEVELOCITY_INJECTION_SCRIPT_TOKEN>>/{
    r src/common/token.sh
    d
}' src/gradle/docker/inject-wrapper.template.sh > src/gradle/docker/inject-wrapper.sh

# Maven templates
## Indent script for inclusion in the 'develocity-maven.yml' file.
sed -e 's/^/  /' src/maven/script/inject.sh > build/inject-indented.sh

## Include injection script
sed -e '/<<DEVELOCITY_INJECTION_SCRIPT_MAVEN>>/{
    r build/inject-indented.sh
    d
}' src/maven/develocity-maven.template.yml > build/develocity-maven-without-token.yml

## Include token script
sed -e '/<<DEVELOCITY_INJECTION_SCRIPT_TOKEN>>/{
    r src/common/token.sh
    d
}' build/develocity-maven-without-token.yml > develocity-maven.yml

## Construct wrapper script for the Dockerfile
sed -e '/<<DEVELOCITY_INJECTION_SCRIPT_MAVEN>>/{
    r src/maven/script/inject.sh
    d
}' src/maven/docker/inject-wrapper.template.sh > build/inject-wrapper-without-token.sh

## Include token script
sed -e '/<<DEVELOCITY_INJECTION_SCRIPT_TOKEN>>/{
    r src/common/token.sh
    d
}' build/inject-wrapper-without-token.sh > src/maven/docker/inject-wrapper.sh
