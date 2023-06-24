{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.synergy;

in

{
  options = {

    services.synergy = {
      package = mkOption {
        default = pkgs.synergy;
        defaultText = "pkgs.synergy";
        type = types.package;
        description = lib.mdDoc "The package used for the synergy client and server.";
      };

      client = {
        enable = mkOption {
          default = false;
          type = types.bool;
          description = lib.mdDoc ''
            Whether to enable the Synergy client (receive keyboard and mouse events from a Synergy server).
          '';
        };
        screenName = mkOption {
          default = "";
          type = types.str;
          description = lib.mdDoc ''
            Use the given name instead of the hostname to identify
            ourselves to the server.
          '';
        };
        serverAddress = mkOption {
          type = types.str;
          description = lib.mdDoc ''
            The server address is of the form: [hostname][:port].  The
            hostname must be the address or hostname of the server.  The
            port overrides the default port, 24800.
          '';
        };
        autoStart = mkOption {
          default = true;
          type = types.bool;
          description = lib.mdDoc "Whether the Synergy client should be started automatically.";
        };
        tls = {
          enable = mkEnableOption (lib.mdDoc ''
            Whether TLS encryption should be used.

            Using this requires a TLS certificate that can be
            generated by starting the Synergy GUI once and entering
            a valid product key.
          '');
          cert = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "~/.synergy/SSL/Synergy.pem";
            description = lib.mdDoc "The TLS certificate to use for encryption.";
          };
        };
      };

      server = {
        enable = mkOption {
          default = false;
          type = types.bool;
          description = lib.mdDoc ''
            Whether to enable the Synergy server (send keyboard and mouse events).
          '';
        };
        configFile = mkOption {
          default = "/etc/synergy-server.conf";
          type = types.str;
          description = lib.mdDoc "The Synergy server configuration file.";
        };
        screenName = mkOption {
          default = "";
          type = types.str;
          description = lib.mdDoc ''
            Use the given name instead of the hostname to identify
            this screen in the configuration.
          '';
        };
        address = mkOption {
          default = "";
          type = types.str;
          description = lib.mdDoc "Address on which to listen for clients.";
        };
        autoStart = mkOption {
          default = true;
          type = types.bool;
          description = lib.mdDoc "Whether the Synergy server should be started automatically.";
        };
        tls = {
          enable = mkEnableOption (lib.mdDoc ''
            Whether TLS encryption should be used.

            Using this requires a TLS certificate that can be
            generated by starting the Synergy GUI once and entering
            a valid product key.
          '');
          cert = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "~/.synergy/SSL/Synergy.pem";
            description = lib.mdDoc "The TLS certificate to use for encryption.";
          };
        };
      };
    };

  };


  config = mkMerge [
    (mkIf cfg.client.enable {
      launchd.user.agents."synergy-client" = {
        path = [ config.environment.systemPath ];
        serviceConfig.ProgramArguments = [
          "${cfg.package}/bin/synergyc" "-f"
        ] ++ optionals (cfg.client.tls.enable) [ "--enable-crypto" ]
          ++ optionals (cfg.client.tls.cert != null) [ "--tls-cert" cfg.client.tls.cert ]
          ++ optionals (cfg.client.screenName != "") [ "-n" cfg.client.screenName ]
          ++ [
          cfg.client.serverAddress
        ];
        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = cfg.client.autoStart;
        serviceConfig.ProcessType = "Interactive";
      };
    })

    (mkIf cfg.server.enable {
      launchd.user.agents."synergy-server" = {
        path = [ config.environment.systemPath ];
        serviceConfig.ProgramArguments = [
          "${cfg.package}/bin/synergys" "-c" "${cfg.server.configFile}" "-f"
        ] ++ optionals (cfg.server.tls.enable) [ "--enable-crypto" ]
          ++ optionals (cfg.server.tls.cert != null) [ "--tls-cert" cfg.server.tls.cert ]
          ++ optionals (cfg.server.screenName != "") [ "-n" cfg.server.screenName ]
          ++ optionals (cfg.server.address != "") [ "-a" cfg.server.address ];
        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = cfg.server.autoStart;
        serviceConfig.ProcessType = "Interactive";
      };
    })
  ];
}
