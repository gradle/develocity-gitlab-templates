#!/bin/bash

# Construct the combined 'develocity-gradle.yml' file from the template and the init-script contents.
sed -e '/<<BUILD_RESULT_CAPTURE_INIT_GROOVY>>/{
    r src/gradle/init-scripts/build-result-capture.init.gradle
    d
}' -e '/<<DEVELOCITY_INJECTION_INIT_GRADLE>>/{
    r src/gradle/init-scripts/develocity-injection.init.gradle
    d
}' src/gradle/develocity-gradle.template.yml > develocity-gradle.yml
