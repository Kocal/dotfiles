{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Extensions added on top of each PHP's defaults.
  # opcache is default-on for 8.1/8.4 and built into core for 8.5, so it is NOT
  # listed here (php85 has no separate opcache extension attribute).
  extensions = { enabled, all }: enabled ++ (with all; [
    xdebug
    apcu
    blackfire
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
}
