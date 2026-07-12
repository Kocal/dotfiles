{ inputs, pkgs, config, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Blackfire agent paths. Everything lives under $HOME so nothing depends on the
  # old Homebrew prefix (/opt/homebrew) anymore. The probe (compiled into each PHP)
  # talks to the agent over this socket; the agent forwards traces to blackfire.io.
  homeDir = config.home.homeDirectory;
  blackfireRunDir = "${homeDir}/.local/run";
  blackfireSocket = "${blackfireRunDir}/blackfire-agent.sock";
  blackfireLogDir = "${homeDir}/.local/state/blackfire";
  blackfireConfig = "${homeDir}/.config/blackfire/agent"; # server-id/token (secret, not in git)

  # Extensions added on top of each PHP's defaults.
  # opcache is default-on for 8.1/8.4 and built into core for 8.5, so it is NOT
  # listed here (php85 has no separate opcache extension attribute).
  extensions = { enabled, all }: enabled ++ (with all; [
    xdebug
    apcu
    blackfire
    xsl
    redis
    amqp
    imagick
  ]);

  extraConfig = ''
    memory_limit = 512M

    ; OPcache (present by default on 8.1/8.4, core on 8.5)
    opcache.enable = 1
    opcache.enable_cli = 1

    ; Xdebug is loaded but idle; enable per request with the trigger
    ; (e.g. XDEBUG_TRIGGER=1) so it never slows normal runs.
    xdebug.mode = off
    xdebug.start_with_request = trigger

    ; APCu also in CLI
    apc.enable_cli = 1
  '';

  mkPhp = base: base.buildEnv { inherit extensions extraConfig; };

  php81 = mkPhp inputs.phps.packages.${system}.php81;
  php82 = mkPhp pkgs.php82;
  php83 = mkPhp pkgs.php83;
  php84 = mkPhp pkgs.php84;
  php85 = mkPhp pkgs.php85;

  # Each nixpkgs PHP installs bin/php, so they collide in one profile. Rename the
  # binaries to php8.x (php-fpm8.x, php-config8.x, ...) so all versions coexist and
  # the Symfony CLI can pick one per project via a `.php-version` file.
  versioned = ver: phpEnv: pkgs.runCommand "php-${ver}-bin" { } ''
    mkdir -p $out/bin
    for b in php php-fpm php-config phpize phpdbg; do
      if [ -e "${phpEnv}/bin/''${b}" ]; then
        ln -s "${phpEnv}/bin/''${b}" "$out/bin/''${b}${ver}"
      fi
    done
  '';
in
{
  home.packages = [
    # Default unversioned `php` = 8.4, with a matching Composer.
    php84
    php84.packages.composer

    # Version-specific binaries for the Symfony CLI (.php-version).
    (versioned "8.1" php81)
    (versioned "8.2" php82)
    (versioned "8.3" php83)
    (versioned "8.4" php84)
    (versioned "8.5" php85)

    pkgs.symfony-cli
    pkgs.blackfire # agent + client CLI (the probe is compiled into each PHP above)
  ];

  # Point the Blackfire probe at our agent socket. The probe reads this env var and
  # it overrides the compiled `blackfire.agent_socket` default (which pointed at
  # /opt/homebrew). Symfony's php-fpm runs with clear_env=no, so its workers inherit
  # this from the shell that launched `symfony serve` -> profiling from the Chrome
  # extension reaches the agent.
  home.sessionVariables.BLACKFIRE_AGENT_SOCKET = "unix://${blackfireSocket}";

  # Run the agent as a launchd user service: starts at login, restarts if it dies.
  # Replaces the manual foreground `blackfire agent` and the broken Homebrew service
  # `homebrew.mxcl.blackfire`.
  launchd.agents.blackfire = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        # launchd creates neither the socket dir nor the log dir; make them first.
        "mkdir -p '${blackfireRunDir}' '${blackfireLogDir}' && exec '${pkgs.blackfire}/bin/blackfire' agent:start --config='${blackfireConfig}' --socket='unix://${blackfireSocket}' --log-file='${blackfireLogDir}/agent.log'"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
