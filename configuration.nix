{ config, lib, pkgs, ... }:

let
   piensa = import (builtins.fetchTarball https://github.com/piensa/nur-packages/archive/master.tar.gz) {};
   domain = "puerti.co";
   admin_email = "ingenieroariel@gmail.com";
in rec {
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci"
                                         "usb_storage" "usbhid"
                                         "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  fileSystems."/tmp" = {
    fsType = "tmpfs";
    device = "tmpfs";
    options = [ "nosuid" "nodev" "relatime" "size=5G" ];
  };

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
    };

  fileSystems."/d" =
    { device = "/dev/disk/by-label/data";
      fsType = "btrfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 8;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;

  system.autoUpgrade.channel = "https://nixos.org/channels/nixpkgs-unstable";

  nixpkgs.config = {
    allowUnfree = true;
  };

  nixpkgs.overlays = [ (self: super: {
    nginx = super.nginx.override {
      modules = [
        pkgs.nginxModules.lua
        pkgs.nginxModules.dav
        pkgs.nginxModules.moreheaders
        pkgs.nginxModules.brotli
      ];
    };
  })];

  environment.systemPackages = with pkgs; [
    git vim mutt spectacle
    wget tmux htop git ripgrep unzip
    tcpdump telnet openssh

    minio minio-client

    libxml2 jansson boost jemalloc
    nghttp2

    piensa.imposm
    piensa.puertico-osm
    piensa.kepler
    piensa.fresco
    piensa.colombia
    piensa.jamaica
  ];

  networking = {
     hostName = "nuc";
     nameservers = [ "1.1.1.1" "8.8.8.8"];
     extraHosts = ''
     192.168.192.2 ${networking.hostName} ${domain} fresco.${domain}
     '';
     firewall = {
        enable = true;
        allowedTCPPortRanges = [
           { from = 80; to = 80; }
           { from = 443; to = 444; }
           { from = 9000; to = 9000; }
         ];
        allowedUDPPortRanges = [
           { from = 60000; to = 61000; }
        ];
        allowPing = true;
     };
  };

  time.timeZone = "America/Bogota";

  i18n = {
    consoleFont = "lat9w-16";
    defaultLocale = "en_US.UTF-8";
  };

  security.pam.enableOTPW = true;

  services.openssh = {
    enable = true;
    ports = [ 444 ];
    gatewayPorts = "yes";
    passwordAuthentication = false; 
    permitRootLogin = "no";
  };

  programs.mosh.enable = true;

  programs.sway-beta = {
    enable = true;
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      # needs qt5.qtwayland in systemPackages
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      # Fix for some Java AWT applications (e.g. Android Studio),
      # use this if they aren't displayed properly:
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';

  ##
  ## If you have issues with delete not working on root, here is the fix:
  # nix-shell -p ncurses
  # infocmp -Cr > termite.terminfo
  # tic -x termite.terminfo
  #
  };


  users.users.x = {
    isNormalUser = true;
    home = "/x";
    extraGroups = ["libvirtd"];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2SGK2vk4KGjkqUcDEdBYwHLj9utMTTShyPYAWBQx8jL0ezUoHqPl7ChJqLuI2ZWMVTW2QnGHl2oZjJRK6ngF0i9hhpjjONEHOdK9YHHaXeUXgad0mAT1R+365jIR1PYOvx9kC7pk8V1Iw3EHmnRRlAHtH19sAfGiyUopZ/N2gjVE0QMhotlKjwDlG9mQR/iFJq604R/nvAvTNXgHuuVou25t1kJkGNxAbiy3jOjKQHlR4NTTB2ttAtodJDU45+FNIWOiZYLbolYdAt9VLIYngDv9aSbxUCsF2ObHZ+Ovqmx0+BK1EKkZ01SYgwIQp3Nfk09xx03y28oFlvG+O6GX3 x@xs-MacBook.local" ];


    packages = with pkgs; [
      wget vim tmux htop git ripgrep mosh killall
      qemu nixops
      gtk3 qt5.qtwayland  swaylock swayidle dmenu i3status i3status-rust termite rofi light firefox-wayland vlc brightnessctl grim slurp 
      kmail vscode
      spectacle
      blender godot gimp inkscape krita audacity
      libreoffice
    ];

  };


  users.users.puertico = {
    home = "/d";
    isNormalUser = false;
  };

security.acme.certs = {
  "${domain}" = {
    webroot = "/d/challenges/";
    email = "${admin_email}";
  };
 "fresco.${domain}" = {
    webroot = "/d/challenges/";
    email = "${admin_email}";
  };
};

services.minio = {
  enable = true;
  dataDir = "/d/minio";
  browser = true;
};

services.postgresql = {
    enable = true;
    package = pkgs.postgresql_11;
    enableTCPIP = true;
    extraPlugins = [ (pkgs.postgis.override { postgresql = pkgs.postgresql_11; }) ];

    authentication = pkgs.lib.mkOverride 10 ''
      local postgres all ident
      host puertico puertico localhost trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE puertico;
      CREATE DATABASE puertico;
      GRANT ALL PRIVILEGES ON DATABASE puertico TO puertico;

      ALTER ROLE puertico WITH LOGIN;

      \c puertico;

      CREATE EXTENSION postgis;
      CREATE EXTENSION hstore;

      CREATE TABLE maps (
        id serial PRIMARY KEY,
        datasets jsonb,
        config jsonb,
        info jsonb,
        created_at timestamp DEFAULT current_timestamp
      );

      INSERT INTO maps(datasets, config, info) VALUES (
          '{ "layers": [] }'::jsonb,
          '{ "bbox": [] }'::jsonb,
          '{ "contact": { "phone": "555-5555" } }'::jsonb
      ); 

      GRANT ALL privileges ON TABLE maps TO puertico;

    '';
};

 systemd.services.hydra = {
   description = "ORY Hydra";
   serviceConfig = {
     LimitNOFILE=65536;
     PermissionsStartOnly=true;
     Type="simple";
     ExecStart = "${piensa.hydra}/bin/hydra serve all --dangerous-force-http";
     ExecStop = "/run/current-system/sw/bin/pkill hydra";
     ExecStartPre = "${piensa.hydra}/bin/hydra migrate sql -e";
     Restart = "on-failure";
     User = "puertico";
     EnvironmentFile = pkgs.writeText "hydra-env" ''
       DATABASE_URL="postgres://puertico:puertico@localhost:5432/puertico?sslmode=disable"
       OAUTH2_ISSUER_URL="https://${domain}/hydra"
       OAUTH2_CONSENT_URL="https://${domain}/consent"
       OAUTH2_LOGIN_URL="https://${domain}/login"
       OAUTH2_ISSUER_URL=http://localhost:4444
       SYSTEM_SECRET="unsafe-way-to-set-the-system-secret"
     '';
   };
   wantedBy = [ "default.target" ];
 };

 systemd.services.oryapi = {
   description = "ORY Oathkeeper API";
   serviceConfig = {
     Type = "simple";
     ExecStart = "${piensa.oathkeeper}/bin/oathkeeper serve api";
     ExecStop = "/run/current-system/sw/bin/pkill oathkeeper";
     ExecStartPre = "${piensa.oathkeeper}/bin/oathkeeper migrate sql -e";
     Restart = "on-failure";
     User= "puertico";
     EnvironmentFile = pkgs.writeText "hydra-env" ''
       PORT=4456
       DATABASE_URL="postgres://puertico:puertico@localhost:5432/puertico?sslmode=disable"
       ISSUER_URL=http://localhost:4455/
       DATABASE_URL="postgres://puertico:puertico@localhost:5432/puertico?sslmode=disable"
       CREDENTIALS_ISSUER_ID_TOKEN_HS256_SECRET="12345678901234567890123456789012"
       AUTHORIZER_KETO_WARDEN_KETO_URL=http://localhost:4466
       CREDENTIALS_ISSUER_ID_TOKEN_ALGORITHM=ory-hydra
       CREDENTIALS_ISSUER_ID_TOKEN_HYDRA_JWK_SET_ID=resources:hydra:jwk:oathkeeper
       CREDENTIALS_ISSUER_ID_TOKEN_HYDRA_ADMIN_URL=http://localhost:4445
       CREDENTIALS_ISSUER_ID_TOKEN_LIFESPAN=1h
       CREDENTIALS_ISSUER_ID_TOKEN_ISSUER=http://localhost:4456
       CREDENTIALS_ISSUER_ID_TOKEN_JWK_REFRESH_INTERVAL=30m
       AUTHENTICATOR_OAUTH2_INTROSPECTION_URL=http://localhost:4445/oauth2/introspect
       AUTHENTICATOR_OAUTH2_CLIENT_CREDENTIALS_TOKEN_URL=http://localhost:4444/oauth2/token
     '';
   };
   wantedBy = [ "default.target" ];
 };

 systemd.services.oryproxy = {
   description = "ORY Oathkeeper Proxy";
   serviceConfig = {
     Type = "simple";
     ExecStart = "${piensa.oathkeeper}/bin/oathkeeper serve proxy";
     ExecStop = "/run/current-system/sw/bin/pkill oathkeeper";
     ExecStartPre = "${piensa.oathkeeper}/bin/oathkeeper migrate sql -e";
     Restart = "on-failure";
     User= "puertico";
     EnvironmentFile = pkgs.writeText "ory-proxy-env" ''
       PORT=4455
       OATHKEEPER_API_URL=http://localhost:4456/
       ISSUER_URL=http://localhost:4455/
       DATABASE_URL="postgres://puertico:puertico@localhost:5432/puertico?sslmode=disable"
       CREDENTIALS_ISSUER_ID_TOKEN_HS256_SECRET="12345678901234567890123456789012"
       AUTHORIZER_KETO_WARDEN_KETO_URL=http://localhost:4466
       CREDENTIALS_ISSUER_ID_TOKEN_ALGORITHM=ory-hydra
       CREDENTIALS_ISSUER_ID_TOKEN_HYDRA_JWK_SET_ID=resources:hydra:jwk:oathkeeper
       CREDENTIALS_ISSUER_ID_TOKEN_HYDRA_ADMIN_URL=http://localhost:4445
       CREDENTIALS_ISSUER_ID_TOKEN_LIFESPAN=1h
       CREDENTIALS_ISSUER_ID_TOKEN_ISSUER=http://localhost:4456
       CREDENTIALS_ISSUER_ID_TOKEN_JWK_REFRESH_INTERVAL=30m
       AUTHENTICATOR_OAUTH2_INTROSPECTION_URL=http://localhost:4445/oauth2/introspect
       AUTHENTICATOR_OAUTH2_CLIENT_CREDENTIALS_TOKEN_URL=http://localhost:4444/oauth2/token
     '';

   };

    after = [ "oryapi.service" "keto.service" "hydra.service"];
    requires = [ "oryapi.service" "keto.service" "hydra.service" ]; 
    wantedBy = [ "default.target" ];
 };

 systemd.services.keto = {
   description = "ORY Keto";
   serviceConfig = {
     Type = "simple";
     ExecStart = "${piensa.keto}/bin/keto serve";
     ExecStop = "/run/current-system/sw/bin/pkill keto";
     ExecStartPre = "${piensa.keto}/bin/keto migrate sql -e";
     Restart = "on-failure";
     User= "puertico";
     EnvironmentFile = pkgs.writeText "hydra-env" ''
       DATABASE_URL="postgres://puertico:puertico@localhost:5432/puertico?sslmode=disable"
       COMPILER_DIR="/d/keto_compiler"
       ISSUER_URL=http://localhost:4455/
       AUTHENTICATOR_OAUTH2_CLIENT_CREDENTIALS_TOKEN_URL=http://localhost:4444/oauth2/token
       AUTHENTICATOR_OAUTH2_INTROSPECTION_URL=http://localhost:4445/oauth2/introspect
     '';
   };
   after = [ "hydra.service"];
   requires = [ "hydra.service" ]; 
  
   wantedBy = [ "default.target" ];
 };

 systemd.services.tegola = {
   description = "Tegola - Mapbox Vector Tiles Server";
   serviceConfig = {
     Type = "simple";
     ExecStart = "${piensa.tegola}/bin/tegola server --config=/d/tegola/tegola.toml";
     ExecStop = "/run/current-system/sw/bin/pkill tegola";
     Restart = "on-failure";
     User= "puertico";
   };
   wantedBy = [ "default.target" ];
 };

 systemd.services.logico = {
   description = "Logico - ORY Login and Consent";
   serviceConfig = {
     Type = "simple";
     ExecStart = "${piensa.logico}/bin/logico";
     ExecStop = "/run/current-system/sw/bin/pkill logico";
     Restart = "on-failure";
     User= "puertico";
     EnvironmentFile = pkgs.writeText "logico-env" ''
      DB_USER=puertico
      DB_PW=puertico
      DB_NAME=puertico
      DB_HOST=localhost
      DB_PORT=5432
      HYDRA_BROWSER_URL=http://${domain}/oauth2/auth
      HYDRA_PUBLIC_URL=https://${domain}/oauth2/token
      HYDRA_ADMIN_URL=http://localhost:4445
      HYDRA_CLIENT_ID=piensa
      HYDRA_CLIENT_SECRET=piensa
      HYDRA_SCOPES=openid,offline,eat,sleep,rave,repeat
      PORT=3000
     '';
   };
   wantedBy = [ "default.target" ];
 };

 systemd.services.hydra.enable = true;
 systemd.services.oryproxy.enable = true;
 systemd.services.oryapi.enable = true;
 systemd.services.keto.enable = true;
 systemd.services.logico.enable = true;
 systemd.services.tegola.enable = true;


services.nginx = {
  enable = true;
  user = "puertico";
  recommendedGzipSettings = true;
  recommendedOptimisation = true;
  package = pkgs.nginx;
  config = ''
  events {
    worker_connections  4096;
  }
  http {
    include       ${pkgs.nginx}/conf/mime.types;
    default_type  application/octet-stream;
    brotli on;
    brotli_static on;
    brotli_types *;
    brotli_comp_level 6;

    server {
      listen 80;
      server_name ${domain};
      return 301 https://$server_name$request_uri;
      add_header Strict-Transport-Security "max-age=15768000;" always;

      location /.well-known/acme-challenge {
         root /d/challenges/;
      }
    }

    server {
      listen 80;
      server_name fresco.${domain};

      location /.well-known/acme-challenge {
         root /d/challenges/;
      }
    }

    server {
      listen 443 ssl http2; 
      server_name fresco.${domain};

      ssl_certificate /var/lib/acme/fresco.${domain}/fullchain.pem;
      ssl_certificate_key /var/lib/acme/fresco.${domain}/key.pem;
      ssl_protocols TLSv1.2 TLSv1.3;
      ssl_prefer_server_ciphers on;
      ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+aRSA+SHA384 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";
      ssl_session_cache shared:ssl_session_cache:10m;
      add_header Strict-Transport-Security "max-age=15768000; includeSubDomains" always;

      location / {
         root /d/fresco.${domain}/;

        if ($request_method = 'OPTIONS') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
          add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
          add_header 'Access-Control-Max-Age' 1728000;
          add_header 'Content-Type' 'text/plain; charset=utf-8';
          add_header 'Content-Length' 0;
          return 204;
        }

        if ($request_method = 'POST') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
          add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
          add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
        }

        if ($request_method = 'GET') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
          add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
          add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
        }

      }
    }

    server {
      listen 443 ssl http2;
      server_name ${domain};
      ssl_certificate /var/lib/acme/${domain}/fullchain.pem;
      ssl_certificate_key /var/lib/acme/${domain}/key.pem;
      add_header Strict-Transport-Security "max-age=15768000; includeSubDomains" always;

    
      ssl_protocols TLSv1.2 TLSv1.3;
      ssl_prefer_server_ciphers on;
      ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+aRSA+SHA384 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";
      ssl_session_cache shared:ssl_session_cache:10m;

      # for minio
      ignore_invalid_headers off;
      client_max_body_size 1000m;
      proxy_buffering off;

      root "/d/${domain}";

      location /tegola {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect     off;

        proxy_pass http://localhost:9090/;
      }

      location /logico/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect     off;

        proxy_pass http://localhost:3000/;
      }

      location /fresco/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect     off;

        proxy_pass http://fresco.${domain}/;
      }

      location /capabilities {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect     off;

	proxy_pass http://localhost:9090/capabilities;
      }

       location /maps {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect     off;

	proxy_pass http://localhost:9090/maps;
      }


      location /oauth2/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:4444/oauth2/;
      }

      location /keto {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:4466/;
      }

      location /oryapi {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:4456/;
      }

      location /oryproxy {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:4455/;
      }

      location /minio {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass https://localhost:9000/;
      }

      location / {
       # Do not serve anything unless it is http2
       if ($server_protocol = HTTP/1.0) {
         return 444;
       }

       if ($server_protocol = HTTP/1.1) {
          return 444;
       } 

        if ($request_method = 'OPTIONS') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
          add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
          add_header 'Access-Control-Max-Age' 1728000;
          add_header 'Content-Type' 'text/plain; charset=utf-8';
          add_header 'Content-Length' 0;
          return 204;
        }

        if ($request_method = 'POST') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
          add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
          add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
        }

        if ($request_method = 'GET') {
          add_header 'Access-Control-Allow-Origin' '*';
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
          add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
          add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
        }

      }

      location /kepler {
          index index.html;
      }

      location /kepler/index.html {
        http2_push kepler@0.2.1/umd/keplergl.min.js;
        http2_push react-redux@4.4.9/dist/react-redux.min.js;
      }

      location /wfs {
        default_type application/json;
        content_by_lua_block {
          local cjson = require "cjson"
          local server_name = ngx.var.server_name
          local protocol = "https://"
          local json = cjson.encode({
            links = {
              { 
                href = protocol .. server_name,
                rel = "self",
                type = "application/json",
                title = "this document"
              },
              { 
                href = protocol .. server_name .. "/api",
                rel = "service",
                type = "application/openapi+json;version=3.0",
                title = "the API definition"
              },
              { 
                href = protocol .. server_name .. "/conformance",
                rel = "conformance",
                type = "application/json",
                title = "WFS 3.0 conformance classes implemented by this server"
              },
              { 
                href = protocol .. server_name .. "/collections",
                rel = "data",
                type = "application/json",
                title = "Metadata about the feature collections"
              }
            }
          }):gsub("\\/", "/")
          ngx.say(json)
        }
      }

    location /api {
       default_type 'application/openapi+json;version=3.0';
       content_by_lua_block {
         local cjson = require "cjson"
         local server_name = ngx.var.server_name
         local protocol = "https://"
         local json = cjson.encode({
            openapi = "3.0.1",
            info = { 
              title = "A sample API conforming to the OGC Web Feature Service standard",
              version = "M1",
              description = "OGC WFS 3.0 OpenAPI definition. (conformance  classes: Core, GeoJSON, HTML and OpenAPI 3.0",
              contact = {
                 name = "Ariel Núñez",
                 email = "${admin_email}",
                 url = protocol .. server_name,
              },
              license = {
                name = "CC-BY 4.0 License",
                url = "https://creativecommons.org/licenses/by/4.0/"
              }
            },
            servers = {
              { url = protocol .. server_name,
                description = "Production server"
              }
            },
            paths = { },
            components = { },
            tags = { 
              {
                name = "Features",
                description = "Access to data (features)."
              },
              {
                name = "Capabilities",
                description = "Essential characteristics of this API including information about the data."
              }
            }
         }):gsub("\\/", "/")
         ngx.say(json)
       }
    }

    location /conformance {
       default_type text/plain;
       content_by_lua_block {
         ngx.say('conformance')
       }
    }

    location /collections {
       default_type text/plain;
       content_by_lua_block {
         ngx.say('collections')
       }
      } 
     }
    }
 
 '';

};
}

