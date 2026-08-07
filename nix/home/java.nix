{ pkgs, lib, profile, ... }:
let
  isPerso = profile == "perso";
  # JDKs available for Gradle/Maven toolchains. jdk21 = OpenJDK 21 LTS, jdk25 =
  # OpenJDK 25 LTS (Azul Zulu builds on darwin). Some projects pin newer JDKs
  # (e.g. idea-php-symfony2-plugin now requires 25), so keep both available.
  jdks = [ pkgs.jdk21 pkgs.jdk25 ];
  # Only one JDK can own `java`/`javac` on PATH; installing several into
  # home.packages collides in buildEnv (shared demo/ files). Put the default on
  # PATH; the rest stay reachable via the Gradle toolchain paths below.
  defaultJdk = pkgs.jdk21;
in {
  # Java toolchain (`java`, `javac`, `jar`, ...). Perso-only: not needed on the
  # boulot machine.
  home.packages = lib.optional isPerso defaultJdk;

  # Build tools (Maven, Gradle, JetBrains) look up JAVA_HOME; `.home` is the
  # package's canonical JAVA_HOME path across platforms. Keep the default on 21.
  home.sessionVariables = lib.optionalAttrs isPerso {
    JAVA_HOME = "${defaultJdk.home}";
  };

  # Let Gradle's toolchain auto-detection find every installed JDK by path, so a
  # project pinned to any of them builds with a plain `./gradlew` regardless of
  # which one JAVA_HOME points at.
  home.file.".gradle/gradle.properties" = lib.mkIf isPerso {
    text = "org.gradle.java.installations.paths=${lib.concatMapStringsSep "," (jdk: jdk.home) jdks}\n";
  };
}
