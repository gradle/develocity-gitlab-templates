#!/bin/bash

mkdir build

# Copy the init-scripts to the build directory and indent them for inclusion in the 'develocity-gradle.yml' file.
sed -e 's/^/      /' src/gradle/init-scripts/build-result-capture.init.gradle > build/build-result-capture.init.gradle
sed -e 's/^/      /' src/gradle/init-scripts/develocity-injection.init.gradle > build/develocity-injection.init.gradle

# Construct the combined 'develocity-gradle.yml' file from the template and the init-script contents.
sed -e '/<<BUILD_RESULT_CAPTURE_INIT_GROOVY>>/{
    r build/build-result-capture.init.gradle
    d
}' -e '/<<DEVELOCITY_INJECTION_INIT_GRADLE>>/{
    r build/develocity-injection.init.gradle
    d
}' src/gradle/develocity-gradle.template.yml > develocity-gradle.yml
