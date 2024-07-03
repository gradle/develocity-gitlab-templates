ARG GRADLE_BASE_IMAGE_VERSION=8.8.0-jdk21
FROM gradle:$GRADLE_BASE_IMAGE_VERSION

# Env vars that should be set at runtime
#
# Develocity server URL
ENV DEVELOCITY_URL=https://scans.gradle.com
# Access key that will be used to create short lived tokens for the job, should be passed as a masked variable
#ENV DEVELOCITY_ACCESS_KEY=***
# Short-lived tokens expiry in hours (if not set, default to 2 hours, should be between 1 and 24)
ENV DEVELOCITY_SHORT_LIVED_TOKEN_EXPIRY=2
# Wether injection is enabled
ENV DEVELOCITY_INJECTION_ENABLED=true
# A custom value set on build scans published
ENV DEVELOCITY_AUTO_INJECTION_CUSTOM_VALUE=GitLab
# The Develocity plugin version
ENV DEVELOCITY_PLUGIN_VERSION=3.17.5
# Common Custom User Data Gradle Plugin version (see https://github.com/gradle/common-custom-user-data-gradle-plugin/)
ENV DEVELOCITY_CCUD_PLUGIN_VERSION=2.0.2
# Wether to allow publishing to a non https (or https untrusted) Develocity server
ENV DEVELOCITY_ALLOW_UNTRUSTED_SERVER=false
# Enforce the url over any defined locally to the project
ENV DEVELOCITY_ENFORCE_URL=false
# Capture file fingerprints, only set if no Develocity plugin is already present
ENV DEVELOCITY_CAPTURE_FILE_FINGERPRINTS=true
# Develocity Gradle plugin repository URL, defaults in the init script to https://plugins.gradle.org/m2
ENV GRADLE_PLUGIN_REPOSITORY_URL=https://plugins.gradle.org/m2
# Develocity Gradle plugin repository username
ENV GRADLE_PLUGIN_REPOSITORY_USERNAME=""
# Develocity Gradle plugin repository password
ENV GRADLE_PLUGIN_REPOSITORY_PASSWORD=""
# Internal do not change
ENV DEVELOCITY_INJECTION_INIT_SCRIPT_NAME=init.gradle

COPY src/gradle/init-scripts/develocity-injection.init.gradle $GRADLE_HOME/init.d/$DEVELOCITY_INJECTION_INIT_SCRIPT_NAME

COPY src/gradle/docker/inject-wrapper.sh /inject-wrapper.sh
RUN chmod +x /inject-wrapper.sh

ENTRYPOINT ["/inject-wrapper.sh"]
