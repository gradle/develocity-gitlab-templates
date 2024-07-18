ARG MAVEN_BASE_IMAGE_VERSION=3.9.8-eclipse-temurin-21
FROM maven:$MAVEN_BASE_IMAGE_VERSION

# Build argument to customize extensions downloading
ARG MAVEN_REPO=https://repo1.maven.org/maven2
ARG CCUD_MAVEN_EXTENSION_VERSION=2.0
ARG MAVEN_EXTENSION_VERSION=1.21.5

# Env vars that should be set at runtime
# Develocity server URL
ENV DEVELOCITY_URL=https://scans.gradle.com
# Access key that will be used to create short lived tokens for the job, should be passed as a masked variable
#ENV DEVELOCITY_ACCESS_KEY=***
# Short-lived tokens expiry in hours (if not set, default to 2 hours, should be between 1 and 24)
ENV DEVELOCITY_SHORT_LIVED_TOKEN_EXPIRY=2
# Wether to allow publishing to a non https (or https untrusted) Develocity server
ENV DEVELOCITY_ALLOW_UNTRUSTED_SERVER=false
# Capture file fingerprints, only set if no Develocity plugin is already present
ENV DEVELOCITY_CAPTURE_FILE_FINGERPRINTS=true
# Enforce the url over any defined locally to the project
ENV DEVELOCITY_ENFORCE_URL=false

# Internal env vars consumed by inject-wrapper.sh
ENV DEVELOCITY_EXT_PATH=/develocity-maven-extension-$MAVEN_EXTENSION_VERSION.jar
ENV CCUD_EXT_PATH=/common-custom-user-data-maven-extension-$CCUD_MAVEN_EXTENSION_VERSION.jar

RUN <<EOF
curl -v "${MAVEN_REPO}/com/gradle/common-custom-user-data-maven-extension/${CCUD_MAVEN_EXTENSION_VERSION}/common-custom-user-data-maven-extension-${CCUD_MAVEN_EXTENSION_VERSION}.jar" -o "${CCUD_EXT_PATH}"
curl -v "${MAVEN_REPO}/com/gradle/develocity-maven-extension/${MAVEN_EXTENSION_VERSION}/develocity-maven-extension-${MAVEN_EXTENSION_VERSION}.jar" -o "${DEVELOCITY_EXT_PATH}"
EOF

COPY src/maven/docker/inject-wrapper.sh /inject-wrapper.sh
RUN chmod +x /inject-wrapper.sh

ENTRYPOINT ["/inject-wrapper.sh"]
