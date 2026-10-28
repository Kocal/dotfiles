{ lib, profile, ... }:
let
  isPerso = profile == "perso";
  # Homebrew JDKs (keg-only `openjdk@*` brews). Some projects pin newer JDKs
  # (e.g. idea-php-symfony2-plugin now requires 25), so keep both available.
  jdkHome = ver: "/opt/homebrew/opt/openjdk@${ver}/libexec/openjdk.jdk/Contents/Home";
  jdks = map jdkHome [ "21" "25" ];
in {
  # Build tools (Maven, Gradle, JetBrains) look up JAVA_HOME, and macOS's
  # /usr/bin/java stub follows it too, so no PATH entry is needed. Default on 21.
  home.sessionVariables = lib.optionalAttrs isPerso {
    JAVA_HOME = jdkHome "21";
  };

  # Let Gradle's toolchain auto-detection find every installed JDK by path, so a
  # project pinned to any of them builds with a plain `./gradlew` regardless of
  # which one JAVA_HOME points at.
  home.file.".gradle/gradle.properties" = lib.mkIf isPerso {
    text = "org.gradle.java.installations.paths=${lib.concatStringsSep "," jdks}\n";
  };
}
