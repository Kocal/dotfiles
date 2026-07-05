{ pkgs, ... }: {
  # Java toolchain. `java`, `javac`, `jar`, ...
  # jdk21 = OpenJDK 21 LTS (Azul Zulu build on darwin).
  home.packages = [
    pkgs.jdk21
  ];

  # Build tools (Maven, Gradle, JetBrains) look up JAVA_HOME; `.home` is the
  # package's canonical JAVA_HOME path across platforms.
  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk21.home}";
  };
}
