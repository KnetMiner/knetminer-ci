# Specific secrets and variables for the Java/Maven build flavour

As explained, these adds up to the [general secrets](../secrets-n-variables.md).

```yaml
# These are used in java-maven/maven-settings.xml
CI_MAVEN_REPO_USER: ${{secrets.CI_MAVEN_REPO_USER}}
CI_MAVEN_REPO_PASSWORD: ${{secrets.CI_MAVEN_REPO_PASSWORD}}
```