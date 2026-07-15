{ pkgs, lib, profile, ... }:
let
  isPerso = profile == "perso";
in {
  # Java toolchain (`java`, `javac`, `jar`, ...). jdk21 = OpenJDK 21 LTS (Azul
  # Zulu build on darwin). Perso-only: not needed on the boulot machine.
  home.packages = lib.optionals isPerso [
    pkgs.jdk21
  ];

  # Build tools (Maven, Gradle, JetBrains) look up JAVA_HOME; `.home` is the
  # package's canonical JAVA_HOME path across platforms.
  home.sessionVariables = lib.optionalAttrs isPerso {
    JAVA_HOME = "${pkgs.jdk21.home}";
  };
}
