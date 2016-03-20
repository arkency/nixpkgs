{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.rails-example;
in
{
  options = {
    services.rails-example = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to run rails-example.
        '';
      };
    };
  };

  config = mkIf config.services.rails-example.enable {
    users.extraUsers.rails-example =
      { name = "rails-example";
        home = "/var/lib/rails-example";
        createHome = true;
        description = "Rails-example user";
      };

    environment.systemPackages = [
      pkgs.rails-example
      pkgs.nodejs
      pkgs.postgresql
    ];

    services.postgresql = 
              { enable = true;
                authentication = 
                  ''
                    local all all              trust
                    host  all all 127.0.0.1/32 trust
                    host  all all ::1/128      trust
                  '';
                };

    systemd.services.rails-example =
      { description = "Rails example application";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "postgresql.service" ];
        path = [
          pkgs.rails-example
          pkgs.rails-example.env
          pkgs.nodejs
          pkgs.postgresql
        ];

        preStart = ''
          if ! test -e "/var/lib/rails-example/db-created"; then
            psql postgres -c 'CREATE ROLE "rails-example_production" LOGIN;'
            ${config.services.postgresql.package}/bin/createdb --owner rails-example_production rails-example_production
            touch "/var/lib/rails-example/db-created"
          fi
          psql postgres -c '\l' > /var/lib/rails-example/meh_log
          psql postgres -c '\dg' >> /var/lib/rails-example/meh_log
        '';

        serviceConfig =
          { ExecStart = "${pkgs.rails-example.env}/bin/bundle exec unicorn -c ${pkgs.rails-example}/config/unicorn.rb -E production";
            User = "rails-example";
            PermissionsStartOnly = true; # preStart must be run as root
            WorkingDirectory = "${pkgs.rails-example}";
            RestartSec = 5;
            Restart = "on-failure";
            TimeoutSec = 10;
          };
      };

  };
}

