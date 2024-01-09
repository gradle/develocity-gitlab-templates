# Develocity GitLab Templates

## Overview
These GitLab templates integrate with Develocity for Gradle and Maven builds run via GitLab. Build scans are available as a free service on [scans.gradle.com](https://scans.gradle.com/) and commercially via [Develocity](https://gradle.com/).

![build-scan.png](images/build-scan.png)

For each Gradle and Maven build that is run from GitLab, these templates exposes the links to the created Build Scan® in the CI job logs.
The templates can also be configured to ad-hoc connect Gradle and Maven builds to an existing Develocity instance such that a Build Scan® is published each time a build is run from GitLab.


## Requirements
- GitLab 15.11 since they use [inputs](https://docs.gitlab.com/ee/ci/yaml/includes.html#define-inputs-for-configuration-added-with-include-beta).
- Shell with curl should be available on the executor
- Network access to download from Maven central and from GitHub (those URLs can be customized, see [Configuration](#Configuration)

## Configuration
### Gradle Auto-instrumentation
Include the remote template and optionally pass inputs.
To enable Build Scan publishing for Gradle builds, the configuration would look something like presented below (using https://develocity.mycompany.com/ as an example of Develocity server URL.

```yml
include:
  - remote: 'https://raw.githubusercontent.com/gradle/develocity-gitlab-templates/1.1.0/develocity-gradle.yml'
    inputs:
      url: https://develocity.mycompany.com

build-gradle-job:
  stage: build
  before_script:
    - !reference [.injectDevelocityForGradle]
  script:
    - ./gradlew check -I $DEVELOCITY_INIT_SCRIPT_PATH # Will publish a build scan to https://develocity.mycompany.com
```
The `.injectDevelocityForGradle` creates an init script with the instrumentation logic and exports the path as `$DEVELOCITY_INIT_SCRIPT_PATH` environment variable.
For all other options see `inputs` section in [develocity-gradle.yml](develocity-gradle.yml).

> **_NOTE:_** The build is also instrumented with our [Common Custom User Data Gradle plugin](https://github.com/gradle/common-custom-user-data-gradle-plugin) as well, as it will provide more details about your build.

### Maven Auto-instrumentation
Include the remote template and optionally pass inputs.
To enable Build Scan publishing for Maven builds, the configuration would look something like presented below (using https://develocity.mycompany.com/ as an example of Develocity server URL.

```yml
include:
  - remote: 'https://raw.githubusercontent.com/gradle/develocity-gitlab-templates/1.1.0/develocity-maven.yml'
    inputs:
      url: https://develocity.mycompany.com

build-maven-job:
  stage: build
  before_script:
    - !reference [.injectDevelocityForMaven]
  script:
    - ./mvnw clean verify # Will publish a build scan to https://develocity.mycompany.com
```

The `.injectDevelocityForMaven` downloads the extensions and references them in `MAVEN_OPTS`.
For all other options see `inputs` section in [develocity-maven.yml](develocity-maven.yml).

> **_NOTE:_** This instrumentation defines the environment variable `MAVEN_OPTS` taken into account by Maven builds. If `MAVEN_OPTS` is redefined, the instrumentation won't work

> **_NOTE:_** The build is also instrumented with our [Common Custom User Data Maven extension](https://github.com/gradle/common-custom-user-data-maven-extension) as well, as it will provide more details about your build

### Gradle and Maven Auto-instrumentation
If you have both Gradle and Maven builds in a pipeline, you can simply just include both templates:

```yml
include:
  - remote: "https://raw.githubusercontent.com/gradle/develocity-gitlab-templates/1.1.0/develocity-gradle.yml"
    inputs:
      url: https://develocity.mycompany.com
  - remote: "https://raw.githubusercontent.com/gradle/develocity-gitlab-templates/1.1.0/develocity-maven.yml"
    inputs:
      url: https://develocity.mycompany.com

build-maven-job:
  stage: build
  before_script:
    - !reference [.injectDevelocityForMaven]
  script:
    - ./mvnw clean verify # Will publish a build scan to https://develocity.mycompany.com

build-gradle-job:
  stage: build
  before_script:
    - !reference [.injectDevelocityForGradle]
  script:
    - ./gradlew check -I $DEVELOCITY_INIT_SCRIPT_PATH # Will publish a build scan to https://develocity.mycompany.com
```

### Auto-instrumentation compatibility
The following sections list the compatibility of the instrumented Develocity Gradle plugin and Develocity Maven extension with the Develocity version based on the given build tool in use.
#### For Gradle builds
For Gradle builds the version used for the Develocity Gradle plugin can be defined with the `gradlePluginVersion` input. The compatibility of the specified version with Develocity can be found [here](https://docs.gradle.com/enterprise/compatibility/#gradle_enterprise_gradle_plugin).
For the Common Custom User Data Gradle plugin which is defined with the `ccudPluginVersion` input, you can see the compatibility of the specified version with the Develocity Gradle plugin [here](https://github.com/gradle/common-custom-user-data-gradle-plugin#version-compatibility).

#### For Maven builds
For Maven builds the version used for the Develocity Maven extension can be defined with the `mavenExtensionVersion` input. The compatibility of the specified version with Develocity can be found [here](https://docs.gradle.com/enterprise/maven-extension/#compatibility_with_apache_maven_and_gradle_enterprise).
For the Common Custom User Data Maven extension which is defined with the `ccudMavenExtensionVersion` input, you can see the compatibility of the specified version with the Develocity Maven extension [here](https://github.com/gradle/common-custom-user-data-maven-extension#version-compatibility).

## Authentication
To authenticate against the Develocity server, you should specify a masked environment variable named `DEVELOCITY_ACCESS_KEY`.
See [here](https://docs.gitlab.com/ee/ci/variables/#define-a-cicd-variable-in-the-ui) on how to do this in GitLab UI.
To generate a Develocity Access Key, you can check [Develocity Gradle plugin docs](https://docs.gradle.com/enterprise/gradle-plugin/#manual_access_key_configuration) and [Develocity Maven extension docs](https://docs.gradle.com/enterprise/maven-extension/#manual_access_key_configuration).

## License
This project is available under the [Apache License, Version 2.0](https://github.com/gradle/rprise-bamboo-plugin/blob/main/LICENSE).
