ARG MAVEN_BASE_IMAGE_VERSION=3.9.8
FROM maven:$MAVEN_BASE_IMAGE_VERSION

# Build argument to customize extensions downloading
ARG mavenRepo=https://repo1.maven.org/maven2
ARG ccudMavenExtensionVersion=2.0
ARG mavenExtensionVersion=1.21.5
ARG extPath=$HOME

# Env vars that should be set at runtime
ENV DEVELOCITY_URL=https://scans.gradle.com
#ENV DEVELOCITY_ACCESS_KEY=***
ENV ALLOW_UNTRUSTED_SERVER=false
ENV SHORT_LIVED_TOKEN_EXPIRY=2
ENV ENFORCE_URL=false
ENV CUSTOM_MAVEN_EXTENSION_COORDINATES=""
ENV CUSTOM_CCUD_COORDINATES=""

# Internal env vars consumed by inject-wrapper.sh
ENV DEVELOCITY_EXT_PATH=$extPath/gradle-enterprise-maven-extension-$mavenExtensionVersion.jar
ENV CCUD_EXT_PATH=$extPath/common-custom-user-data-maven-extension-$ccudMavenExtensionVersion.jar

RUN <<EOF
curl -v "${mavenRepo}/com/gradle/common-custom-user-data-maven-extension/${ccudMavenExtensionVersion}/common-custom-user-data-maven-extension-${ccudMavenExtensionVersion}.jar" -o "${CCUD_EXT_PATH}"
curl -v "${mavenRepo}/com/gradle/develocity-maven-extension/${mavenExtensionVersion}/develocity-maven-extension-${mavenExtensionVersion}.jar" -o "${DEVELOCITY_EXT_PATH}"
EOF

COPY inject-wrapper.sh /inject-wrapper.sh
RUN chmod +x /inject-wrapper.sh

ENTRYPOINT ["/inject-wrapper.sh"]
