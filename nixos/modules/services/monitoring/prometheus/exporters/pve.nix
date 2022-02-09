{ config, lib, pkgs, options }:

with lib;
let
  cfg = config.services.prometheus.exporters.pve;
  computedConfigText = {
    default = {
      user = cfg.user;
      password = cfg.password;
      # ignore token auth if basic auth creds are specified
      token_name = "${if user == null then cfg.tokenName else null}";
      token_path = "${if user == null then cfg.tokenPath else null}";
      #optional args
      verify_ssl = cfg.verifySSL;
    };
  };
  computedConfigFile = "${if cfg.configFile == null then generators.toYAML computedConfigText else cfg.configFile}";
in
{
  port = 9221;
  extraOpts = {
    package = mkOption {
      type = types.package;
      default = pkgs.prometheus-pve-exporter;
      defaultText = literalExpression "pkgs.prometheus-pve-exporter";
      example = literalExpression "pkgs.prometheus-pve-exporter";
      description = ''
        The package to use for prometheus-pve-exporter
      '';
    };
    user = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "user@pve";
      description = ''
        PVE API basic authentication username.

        This option, when present, overrides any token-based auth options.
      '';
    };
    password = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "pAs$w0Rd123";
      description = ''
        PVE API basic authentication password.
      '';
    };
    tokenName = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Token name for PVE API token-based authentication.
      '';
    };
    tokenPath = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        Token path for PVE API token-based authentication.
      '';
    };
    verifySSL = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Option to verify PVE API endpoint's TLS certificate
      '';
    };
    configFile = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "/etc/pve.yml";
      description = ''
        Path to the config file. Overrides all other configuration options (except collectors).
      '';
    };
    collectors = {
      status = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Collect Node/VM/CT status
        '';
      };
      version = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Collect PVE version info
        '';
      };
      node = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Collect PVE node info
        '';
      };
      cluster = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Collect PVE cluster info
        '';
      };
      resources = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Collect PVE resources info
        '';
      };
      config = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Collect PVE onboot status
        '';
      };
    };
  };
  serviceOpts = {
    serviceConfig = {
      ExecStart = ''
        ${cfg.package}/bin/pve_exporter \
          --${if cfg.collectors.status == true then "" else "no-"}collector.status \
          --${if cfg.collectors.version == true then "" else "no-"}collector.version \
          --${if cfg.collectors.node == true then "" else "no-"}collector.node \
          --${if cfg.collectors.cluster == true then "" else "no-"}collector.cluster \
          --${if cfg.collectors.resources == true then "" else "no-"}collector.resources \
          --${if cfg.collectors.config == true then "" else "no-"}collector.config \
          ${computedConfigFile} \
          ${toString cfg.port} ${cfg.listenAddress}
      '';
    };
  };
}
