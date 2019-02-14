{ config, lib, pkgs, ... }:

let
   piensa = pkgs.callPackage ./piensa/default.nix{};
in

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
      ./ui.nix      
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

  system.stateVersion = "18.09"; 

  nixpkgs.config = {
    allowUnfree = true;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball {
      url = "https://github.com/nix-community/NUR/archive/11937cf90187b7cb1eb43b02c8fc3a45cb16fd8b.tar.gz";
      sha256 = "0q485pc2d7m1jl72rd9b5jliq910q03sghg2vwxx5xg3wb8i21sc";
    }
   ){
      inherit pkgs;
  };

  nginx = pkgs.nginx.override {
    modules = [
      pkgs.nginxModules.lua
      pkgs.nginxModules.dav
      pkgs.nginxModules.moreheaders
      pkgs.nginxModules.brotli
    ];
  };

  };

  environment.systemPackages = with pkgs; [
    git vim mutt spectacle
    wget tmux htop git ripgrep unzip
    tcpdump telnet openssh

    minio minio-client

    libxml2 jansson boost jemalloc
    nghttp2

    piensa.imposm
    piensa.kepler
    piensa.fresco
    piensa.colombia
    piensa.jamaica

    firefox inkscape gimp
    #nur.repos.piensa.blender

  ];

  networking = {
     hostName = "nuc";
     nameservers = [ "1.1.1.1" "8.8.8.8"];
     extraHosts = ''
     192.168.192.2 nuc puerti.co
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

  users.users.x = {
    isNormalUser = true;
    home = "/x";
    extraGroups = ["libvirtd"];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2SGK2vk4KGjkqUcDEdBYwHLj9utMTTShyPYAWBQx8jL0ezUoHqPl7ChJqLuI2ZWMVTW2QnGHl2oZjJRK6ngF0i9hhpjjONEHOdK9YHHaXeUXgad0mAT1R+365jIR1PYOvx9kC7pk8V1Iw3EHmnRRlAHtH19sAfGiyUopZ/N2gjVE0QMhotlKjwDlG9mQR/iFJq604R/nvAvTNXgHuuVou25t1kJkGNxAbiy3jOjKQHlR4NTTB2ttAtodJDU45+FNIWOiZYLbolYdAt9VLIYngDv9aSbxUCsF2ObHZ+Ovqmx0+BK1EKkZ01SYgwIQp3Nfk09xx03y28oFlvG+O6GX3 x@xs-MacBook.local" ];

  };

  users.users.puertico = {
    home = "/d";
    isNormalUser = false;
  };

security.acme.certs = {
  "puerti.co" = {
    webroot = "/d/challenges/";
    email = "ingenieroariel@gmail.com";
  };
 "fresco.puerti.co" = {
    webroot = "/d/challenges/";
    email = "ingenieroariel@gmail.com";
  };
};

services.minio = {
  enable = true;
  dataDir = "/d/minio";
  browser = true;
};

services.postgresql = {
    enable = true;
    package = pkgs.postgresql100;
    enableTCPIP = true;
    extraPlugins = [ (pkgs.postgis.override { postgresql = pkgs.postgresql100; }) ];

    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all localhost trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE puertico;
      CREATE DATABASE puertico;
      GRANT ALL PRIVILEGES ON DATABASE puertico TO puertico;

      USE DATABASE puertico;

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
     ExecStart = "${pkgs.nur.repos.piensa.hydra}/bin/hydra serve all --dangerous-force-http";
     ExecStop = "/run/current-system/sw/bin/pkill hydra";
     ExecStartPre = "${pkgs.nur.repos.piensa.hydra}/bin/hydra migrate sql -e";
     Restart = "on-failure";
     User = "puertico";
     EnvironmentFile = pkgs.writeText "hydra-env" ''
       DATABASE_URL="postgres://puertico:puertico@localhost:5432/puertico?sslmode=disable"
       OAUTH2_ISSUER_URL="https://puerti.co/hydra"
       OAUTH2_CONSENT_URL="https://puerti.co/consent"
       OAUTH2_LOGIN_URL="https://puerti.co/login"
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
     ExecStart = "${pkgs.nur.repos.piensa.oathkeeper}/bin/oathkeeper serve api";
     ExecStop = "/run/current-system/sw/bin/pkill oathkeeper";
     ExecStartPre = "${pkgs.nur.repos.piensa.oathkeeper}/bin/oathkeeper migrate sql -e";
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
     ExecStart = "${pkgs.nur.repos.piensa.oathkeeper}/bin/oathkeeper serve proxy";
     ExecStop = "/run/current-system/sw/bin/pkill oathkeeper";
     ExecStartPre = "${pkgs.nur.repos.piensa.oathkeeper}/bin/oathkeeper migrate sql -e";
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
     ExecStart = "${pkgs.nur.repos.piensa.keto}/bin/keto serve";
     ExecStop = "/run/current-system/sw/bin/pkill keto";
     ExecStartPre = "${pkgs.nur.repos.piensa.keto}/bin/keto migrate sql -e";
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
     ExecStart = "${pkgs.nur.repos.piensa.tegola}/bin/tegola server --config=/d/tegola/tegola.toml";
     ExecStop = "/run/current-system/sw/bin/pkill tegola";
     Restart = "on-failure";
     User= "puertico";
   };
   wantedBy = [ "default.target" ];
 };

 systemd.services.pgbouncer = {
   description = "pgbouncer - happy postgres";
   serviceConfig = {
     Type = "simple";
     ExecStart = "${pkgs.pgbouncer}/bin/pgbouncer /d/pgbouncer/pgbouncer.ini";
     ExecStop = "/run/current-system/sw/bin/pkill pgbouncer";
     Restart = "on-failure";
     User= "puertico";
   };
   wantedBy = [ "default.target" ];
 };



 systemd.services.hydra.enable = true;
 systemd.services.oryproxy.enable = true;
 systemd.services.oryapi.enable = true;
 systemd.services.keto.enable = true;
 systemd.services.tegola.enable = true;
 systemd.services.pgbouncer.enable = true;


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
      server_name puerti.co;
      return 301 https://$server_name$request_uri;
      add_header Strict-Transport-Security "max-age=15768000;" always;

      location /.well-known/acme-challenge {
         root /d/challenges/;
      }
    }

    server {
      listen 80;
      server_name fresco.puerti.co;

      location /.well-known/acme-challenge {
         root /d/challenges/;
      }
    }

    server {
      listen 443 ssl http2; 
      server_name fresco.puerti.co;

      ssl_certificate /var/lib/acme/fresco.puerti.co/fullchain.pem;
      ssl_certificate_key /var/lib/acme/fresco.puerti.co/key.pem;
      ssl_protocols TLSv1.2 TLSv1.3;
      ssl_prefer_server_ciphers on;
      ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+aRSA+SHA384 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";
      ssl_session_cache shared:ssl_session_cache:10m;
      add_header Strict-Transport-Security "max-age=15768000; includeSubDomains" always;

      location / {
         root /d/fresco.puerti.co/;
      }
    }

    server {
      listen 443 ssl http2;
      server_name puerti.co;
      ssl_certificate /var/lib/acme/puerti.co/fullchain.pem;
      ssl_certificate_key /var/lib/acme/puerti.co/key.pem;
      add_header Strict-Transport-Security "max-age=15768000; includeSubDomains" always;

    
      ssl_protocols TLSv1.2 TLSv1.3;
      ssl_prefer_server_ciphers on;
      ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+aRSA+SHA384 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";
      ssl_session_cache shared:ssl_session_cache:10m;

      # for minio
      ignore_invalid_headers off;
      client_max_body_size 1000m;
      proxy_buffering off;

      root "/d/puerti.co";

      location /tegola {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect     off;

        proxy_pass http://localhost:9090/;
      }

      location /fresco/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect     off;

        proxy_pass http://fresco.puerti.co/;
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


      location /hydra {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:4444/;
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
          add_header 'Access-Control-Allow-Origin' '$http_origin';
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
          add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
          add_header 'Access-Control-Max-Age' 1728000;
          add_header 'Content-Type' 'text/plain; charset=utf-8';
          add_header 'Content-Length' 0;
          return 204;
        }

        if ($request_method = 'POST') {
          add_header 'Access-Control-Allow-Origin' '$http_origin';
          add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
          add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
          add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
        }

        if ($request_method = 'GET') {
          add_header 'Access-Control-Allow-Origin' '$http_origin';
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
                 email = "ariel@piensa.co",
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

     location /consent {
       default_type text/plain;
       content_by_lua_block {
         ngx.say('Consent area.')
       }

       access_by_lua_block {
         -- Some variable declarations.
         local authorization, err = ngx.req.get_headers()["authorization"]
         
         if authorization then
           -- FIXME: Implement checking the authorization is valid.
           return
         end

         -- Internally rewrite the URL so that we serve
         -- /auth/ if there's no valid token.
	 ngx.exec("/auth/")
       }
      }

       location /login {
         default_type application/json;
         content_by_lua_block {
           local cjson = require "cjson"
           local server_name = ngx.var.server_name
           local protocol = "https://"

           local args = ngx.req.get_uri_args()
           local email = args.email 
           local json = cjson.encode({
               link = protocol .. server_name .. "/login" .. "/one-time-hashed-sign-in-link-sent-via-email",
               secret = "brave platypus",
               email = email,
               description = "Click on the link sent to your email if it contains the words brave platypus to finish the sign in process",
               note = "This link is being returned as a proof of concept, so you can avoid checking your email - will be removed in final release"
           }):gsub("\\/", "/")
           ngx.say(json)
         }
       }
        location ~ login/(?<magic_code>\w+) {
          default_type application/json;
          content_by_lua_block {
            local cjson = require "cjson"
            local server_name = ngx.var.server_name
            local protocol = "https://"
            local magic_code = ngx.var.magic_code

            -- Check magic_code is valid and contact hydra?

            local args = ngx.req.get_uri_args()
            local json = cjson.encode({
              description = "This user is who she claims she is"
            }):gsub("\\/", "/")
            ngx.say(json)
          }
        } 
     }
    }
 
 '';

};

}
