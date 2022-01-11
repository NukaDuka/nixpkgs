{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.mandos;

  clientDefaults = {
    "DEFAULT" = {
      "approval_delay" = "PT0S";
      "approval_duration" = 1;
      "approved_by_default" = true;
      "checker" = "fping -q -- %%(host)s";
      "extended_timeout" = "PT15M";
      "interval" = "PT2M";
      "timeout" = "PT5M";
      "enabled" = true;
    };
  };

  mandosConfText = generators.toINI { } {
    "DEFAULT" = {
      "interface" = cfg.conf.interface;
      "address" = cfg.conf.address;
      "port" = cfg.conf.port;
      "debug" = cfg.conf.debug;
      "priority" = cfg.conf.priority;
      "servicename" = cfg.servicename;
      "use_dbus" = cfg.conf.use_dbus;
      "use_ipv6" = cfg.conf.use_ipv6;
      "restore" = cfg.conf.restore;
      "statedir" = cfg.conf.statedir;
      "socket" = cfg.conf.socket;
    };
  };

  mandosConfFile = pkgs.writeText "mandos.conf" ''
    ${mandosConfText}

    ${optionalString (cfg.extraConfig != null) cfg.extraConfig}
  '';

  mandosClientText = generators.toINI { } cfg.clients;

  mandosClientFile = pkgs.writeText "mandos-clients.conf" mandosClientText;

in
{
  options = {
    services.mandos.conf = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable the mandos-server service.";
        };

        extraConfig = mkOption {
          type = with types; nullOr lines;
          default = null;
          description = "Extra config options as raw text lines";
          example = ''
            address = 127.0.0.1
            interface = eth0
          '';
        };

        extraArgs = mkOption {
          type = with types; nullOr lines;
          default = null;
          description = "Extra command-line options as raw text lines";
          example = ''
            --no-zeroconf
            --foreground
          '';
        };

        package = mkOption {
          type = types.package;
          default = pkgs.mandos;
          defaultText = literalExpression "pkgs.mandos";
          description = "Which mandos-server package to use.";
        };

        interface = mkOption {
          type = with types; nullOr string;
          default = null;
          description = ''
            If this is specified, the server will only announce the service and listen to requests on the specified network interface.

            Default is to use all available interfaces.";
          '';
        };

        address = mkOption {
          type = types.string;
          default = "0.0.0.0";
          description = ''
            If this option is used, the server will only listen to the specified IPv6 address.

            If a link-local address is specified, an interface should be set, since a link-local address is only valid on a single interface.

            By default, the server will listen to all available addresses.

            If set, this must normally be an IPv6 address; an IPv4 address can only be specified using IPv4-mapped IPv6 address syntax: “::FFFF:192.0.2.3”. (Only if use_ipv6 is disabled must this be an IPv4 address.)
          '';
        };

        port = mkOption {
          type = with types; nullOr int;
          default = null;
          description = ''
            If this option is used, the server will bind to that port.

            By default, the server will listen to an arbitrary port given by the operating system.
          '';
        };

        debug = mkOption {
          type = types.bool;
          default = false;
          description = ''
            If the server is run in debug mode, it will run in the foreground and print a lot of debugging information.

            The default is to not run in debug mode.
          '';
        };

        priority = mkOption {
          type = types.string;
          default = "SECURE128​:!CTYPE-X.509​:+CTYPE-RAWPK​:!RSA​:!VERS-ALL​:+VERS-TLS1.3​:%PROFILE_ULTRA";
          description = ''
            GnuTLS priority string for the TLS handshake.

            The default is “SECURE128​:!CTYPE-X.509​:+CTYPE-RAWPK​:!RSA​:!VERS-ALL​:+VERS-TLS1.3​:%PROFILE_ULTRA” when using raw public keys in TLS, and “SECURE256​:!CTYPE-X.509​:+CTYPE-OPENPGP​:!RSA​:+SIGN-DSA-SHA256” when using OpenPGP keys in TLS.

            See gnutls_priority_init(3) for the syntax. Warning: changing this may make the TLS handshake fail, making server-client communication impossible. Changing this option may also make the network traffic decryptable by an attacker.
          '';
        };

        servicename = mkOption {
          type = types.string;
          default = "Mandos";
          description = ''
            Zeroconf service name.

            The default is “Mandos”.

            This only needs to be changed if for some reason is would be necessary to run more than one server on the same host. This would not normally be useful. If there are name collisions on the same network, the newer server will automatically rename itself to “Mandos #2”, and so on; therefore, this option is not needed in that case.
          '';
        };

        use_dbus = mkOption {
          type = types.bool;
          default = true;
          description = ''
            This option controls whether the server will provide a D-Bus system bus interface.

            The default is to provide such an interface.
          '';
        };

        use_ipv6 = mkOption {
          type = types.bool;
          default = true;
          description = ''
            This option controls whether the server will use IPv6 sockets and addresses.

            The default is to use IPv6.

            This option should never normally be turned off, even in IPv4-only environments. This is because mandos-client(8mandos) will normally use IPv6 link-local addresses, and will not be able to find or connect to the server if this option is turned off. Only advanced users should consider changing this option.
          '';
        };

        restore = mkOption {
          type = types.bool;
          default = true;
          description = ''
            This option controls whether the server will restore its state from the last time it ran.

            Default is to restore last state.
          '';
        };

        statedir = mkOption {
          type = types.path;
          default = "/var/lib/mandos";
          description = ''
            Directory to save (and restore) state in.

            Default is “/var/lib/mandos”.
          '';
        };

        socket = mkOption {
          type = with types; nullOr int;
          default = null;
          description = ''
            If this option is used, the server will not create a new network socket, but will instead use the supplied file descriptor.

            By default, the server will create a new network socket.
          '';
        };
    };

    services.mandos.clients = mkOption {
      type = with types; attrsOf attrs;
      default = clientDefaults;
      example = literalExpression ''
        "DEFAULT" = {
          "extended_timeout" = "PT15M";
          "interval" = "PT1M";
          "timeout" = "PT10M";
          "enabled" = false;
        };

        "foo" = {
          "key_id" = "788cd77115cd0bb7b2d5e0ae8496f6b48149d5e712c652076b1fd2d957ef7c1f";
          "fingerprint" =  "7788 2722 5BA7 DE53 9C5A  7CFA 59CF F7CD BD9A 5920";
          "secret" =\'\'
                  hQIOA6QdEjBs2L/HEAf/TCyrDe5Xnm9esa+Pb/vWF9CUqfn4srzVgSu234
                  REJMVv7lBSrPE2132Lmd2gqF1HeLKDJRSVxJpt6xoWOChGHg+TMyXDxK+N
                  Xl89vGvdU1XfhKkVm9MDLOgT5ECDPysDGHFPDhqHOSu3Kaw2DWMV/iH9vz
                  3Z20erVNbdcvyBnuojcoWO/6yfB5EQO0BXp7kcyy00USA3CjD5FGZdoQGI
                  Tb8A/ar0tVA5crSQmaSotm6KmNLhrFnZ5BxX+TiE+eTUTqSloWRY6VAvqW
                  QHC7OASxK5E6RXPBuFH5IohUA2Qbk5AHt99pYvsIPX88j2rWauOokoiKZo
                  t/9leJ8VxO5l3wf/U64IH8bkPIoWmWZfd/nqh4uwGNbCgKMyT+AnvH7kMJ
                  3i7DivfWl2mKLV0PyPHUNva0VQxX6yYjcOhj1R6fCr/at8/NSLe2OhLchz
                  dC+Ls9h+kvJXgF8Sisv+Wk/1RadPLFmraRlqvJwt6Ww21LpiXqXHV2mIgq
                  WnR98YgSvUi3TJHrUQiNc9YyBzuRo0AjgG2C9qiE3FM+Y28+iQ/sR3+bFs
                  zYuZKVTObqiIslwXu7imO0cvvFRgJF/6u3HNFQ4LUTGhiM3FQmC6NNlF3/
                  vJM2hwRDMcJqDd54Twx90Wh+tYz0z7QMsK4ANXWHHWHR0JchnLWmenzbtW
                  5MHdW9AYsNJZAQSOpirE4Xi31CSlWAi9KV+cUCmWF5zOFy1x23P6PjdaRm
                  4T2zw4dxS5NswXWU0sVEXxjs6PYxuIiCTL7vdpx8QjBkrPWDrAbcMyBr2O
                  QlnHIvPzEArRQLo=
          \'\';
          "host" = "foo.example.org";
          "interval" = "PT1M";
        };

        "bar" = {
          "key_id" = "F90C7A81D72D1EA69A51031A91FF8885F36C8B46D155C8C58709A4C99AE9E361";
          "fingerprint" = "3e393aeaefb84c7e89e2f547b3a107558fca3a27";
          "secfile" = /"etc/mandos/bar-secret";
          "timeout" = "PT15M";
          "approved_by_default" = "False";
          "approval_delay" = "PT30S";
        };
      '';
      description = "mandos.clients.conf configuration as nix attributes. Client configuration documentation is available here <https://www.recompile.se/mandos/man/mandos-clients.conf.5> or in the mandos-clients.conf.5 manual page.";
    };
  };

  config = mkIf cfg.enable {
    environment.etc = {
      "mandos/mandos.conf".source = mandosConfFile;
      "mandos/mandos-client.conf".source = mandosClientFile;
      "dbus-1/system.d/mandos.conf".source = "${cfg.conf.package}/etc/dbus-1/systemd.d/mandos.conf";
      "default/mandos/default-mandos".source = "${cfg.conf.package}/etc/default/mandos/default-mandos";
      "init.d/mandos".source = "${cfg.conf.package}/etc/init.d/mandos";
    };

    systemd.services.mandos = {
      description = "Server of encrypted passwords to Mandos clients";
      documentation = "man:intro(8mandos) man:mandos(8)";
      ## If the server is configured to listen to a specific IP or network
      ## interface, it may be necessary to change "network.target" to
      ## "network-online.target".
      after = [ "network.target" "avahi-daemon.service" ];
      requisite = [ "avahi-daemon.service" ];
      serviceConfig = {
        busName = "se.recompile.Mandos";
        environmentFile = "${cfg.conf.package}/etc/default/mandos/default-mandos";
        execStart = "${cfg.conf.package}/sbin/mandos --foreground --configdir /etc/mandos ${concatStringsSep " " cfg.conf.extraArgs}";
        restart = "always";
        killMode = "mixed";
        privateTmp = "yes";
        privateDevices = "yes";
        protectSystem = "full";
        protectHome = "yes";
        capabilityBoundingSet = "CAP_KILL CAP_SETGID CAP_SETUID CAP_DAC_OVERRIDE CAP_NET_RAW";
        protectKernelTunables = "yes";
        protectControlGroups = "yes";
      };
    };
  };
}
