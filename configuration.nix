{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci"
                                         "usb_storage" "usbhid"
                                         "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.kernel.sysctl = { 
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.forwarding" = 1;
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

  nixpkgs.overlays = [
    (self: super:
    let
      inherit (self.pkgs) fetchgit python37Packages;
      inherit (python37Packages) numpy python;
    in {
      blender = (super.blender.override {
      pythonPackages = python37Packages;
    }).overrideAttrs (oldAttrs: rec {
      name = "blender-2.80.beta-${version}";
      version = "38984b10ff7b8c61c5e1b85a971c77841de5f4e7";

      src = fetchgit {
        url = "https://git.blender.org/blender.git";
        rev = version;
        sha256 = "1i1i7bvr293g96hq5vazk2g25kz4hv4qbqhffp84lscb21d395bp";
      };

      cmakeFlags = oldAttrs.cmakeFlags ++ [
        "-DPYTHON_NUMPY_PATH=${numpy}/${python.sitePackages}"
        "-DWITH_PYTHON_INSTALL=ON"
        "-DWITH_PYTHON_INSTALL_NUMPY=ON"
      ];
     });
    }
    ) (self: super:
    let
      inherit (self.pkgs) fetchgit;
      inherit (self.pkgs.nur.repos.piensa) keto;
    in {
      keto = (super.nur.repos.piensa.keto.override { }).overrideAttrs (oldAttrs: rec {
      name = "keto-${version}";
      version = "7798442553cfe7989a23d2c389c8c63a24013543";

      src = fetchgit {
        rev = version;
        url = "https://github.com/ory/keto";
        sha256 = "0ybdm0fp63ygvs7cnky4dqgs5rmw7bd1pqkljwb8c2k14ps8xxyf";
      };

      patches = [ ./0001-keto-changes.patch ];
     });
    }
    )

  ];

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball {
      url = "https://github.com/nix-community/NUR/archive/4ffbef2507ce4977c949567b3bf0790ff120ac82.tar.gz";
      sha256 = "0bxwmb84jj37x57ckyhvgrwcwfkqa9vm7v9l6sv620zwwbaw9rwj";
    }
   ){
      inherit pkgs;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    wget tmux htop git ripgrep unzip
    tcpdump telnet openssh
    gnumake gcc libcxx libcxxabi llvm ninja clang
    python3 nodejs nodePackages.node2nix go
    firefox kmail vscode vlc
    blender godot gimp inkscape krita audacity
    libreoffice

    minio minio-client

    nur.repos.piensa.hydra
    nur.repos.piensa.oathkeeper
    nur.repos.piensa.tegola
    keto

    ( with import <nixpkgs> {};
      vim_configurable.customize {
        name = "vim";
        vimrcConfig.customRC = ''
          syntax enable
          set backspace=indent,eol,start
          if has("autocmd")
             au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
          endif
        '';
      }
      )

    
  ];

  services.dhcpd4 = {
    enable = true; 
    interfaces = [ "wlan0" ];
    extraConfig = ''
       subnet 192.168.3.0 netmask 255.255.255.0 {
         option subnet-mask 255.255.255.0;
         option broadcast-address 192.168.3.255;
         option domain-name-servers 1.1.1.1, 8.8.8.8;
         option routers 192.168.3.1;
         next-server 192.168.3.1;
         range 192.168.3.150 192.168.3.190;
         default-lease-time 21600;
         max-lease-time 43200;
         option ip-forwarding off;
         }
    '';
  };
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


  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.autoLogin.enable = true;
  services.xserver.displayManager.sddm.autoLogin.user = "x";
  services.xserver.desktopManager.plasma5.enable = true;

  security.pam.enableOTPW = true;

  services.openssh = {
    enable = true;
    ports = [ 444 ];
    gatewayPorts = "yes";
    passwordAuthentication = false; 
    permitRootLogin = "no";
  };

  programs.mosh.enable = true;

  virtualisation.libvirtd.enable = true;

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
};

services.minio = {
  enable = true;
  dataDir = "/d/minio";
  browser = false;
};

services.postgresql = {
    enable = true;
    package = pkgs.postgresql100;
    enableTCPIP = true;
    extraPlugins = [ (pkgs.postgis.override { postgresql = pkgs.postgresql100; }) ];

    authentication = pkgs.lib.mkOverride 10 ''
      local all all ident
      host puertico puertico localhost trust
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
       DATABASE_URL="postgres://puertico@localhost:5432/puertico?sslmode=disable"
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
       DATABASE_URL="postgres://puertico@localhost:5432/puertico?sslmode=disable"
       ISSUER_URL=http://localhost:4455/
       DATABASE_URL="postgres://puertico@localhost:5432/puertico?sslmode=disable"
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
       DATABASE_URL="postgres://puertico@localhost:5432/puertico?sslmode=disable"
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
     ExecStart = "${pkgs.keto}/bin/keto serve";
     ExecStop = "/run/current-system/sw/bin/pkill keto";
     ExecStartPre = "${pkgs.keto}/bin/keto migrate sql -e";
     Restart = "on-failure";
     User= "puertico";
     EnvironmentFile = pkgs.writeText "hydra-env" ''
       DATABASE_URL="postgres://puertico@localhost:5432/puertico?sslmode=disable"
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
     Type = "forking";
     ExecStart = "${pkgs.nur.repos.piensa.tegola}/bin/tegola server";
     ExecStop = "/run/current-system/sw/bin/pkill tegola";
     Restart = "on-failure";
     User= "puertico";
   };
   wantedBy = [ "default.target" ];
 };

 systemd.services.hydra.enable = true;
 systemd.services.oryproxy.enable = true;
 systemd.services.oryapi.enable = true;
 systemd.services.keto.enable = true;
 systemd.services.tegola.enable = false;

services.nginx = {
  enable = true;
  user = "puertico";
  package = pkgs.openresty;
  config = ''
  events {
    worker_connections  4096;
  }
  http {
    include       ${pkgs.nginx}/conf/mime.types;
    default_type  application/octet-stream;

    upstream database {
      postgres_server 127.0.0.1 dbname=puertico user=puertico;
    }

    server {
      listen 80;
      server_name puerti.co;
      return 301 https://$server_name$request_uri;

      location /.well-known/acme-challenge {
         root /d/challenges/;
      }
    }

    server {
      listen 443 ssl http2;
      server_name puerti.co;
      ssl_certificate /var/lib/acme/puerti.co/fullchain.pem;
      ssl_certificate_key /var/lib/acme/puerti.co/key.pem;

      ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
      ssl_prefer_server_ciphers on;
      ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";

      # for minio
      ignore_invalid_headers off;
      client_max_body_size 1000m;
      proxy_buffering off;

      root "/d/puerti.co";


      location /hydra {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:4444;
      }

      location /keto {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:4466;
      }

      location /oryapi {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:4456;
      }

      location /oryproxy {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:4455;
      }

      location / {

        try_files $uri $uri/index.html @minio;
      }

      location @minio {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://localhost:9000;
      }

      location /wfs3 {
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

    location /maps {
      client_max_body_size 500M;
      postgres_pass database;
      rds_json on;
      postgres_query    HEAD GET  "SELECT id, created_at FROM maps";
 
      postgres_escape $body $request_body;
      
      postgres_query
        POST "INSERT INTO maps (datasets, config, info) VALUES($body::jsonb->'datasets', $body::jsonb->'config', $body::jsonb->'info') RETURNING *";
      postgres_rewrite  POST changes 201;
    }

    location ~ /maps/(?<id>\d+).json {


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



      postgres_pass database;
      rds_json  on;
      postgres_escape $escaped_id $id;
      postgres_query    HEAD GET  "SELECT * FROM maps WHERE id=$escaped_id";
      postgres_rewrite  HEAD GET  no_rows 410;

      postgres_escape $body  $request_body;

      postgres_query
        PUT "UPDATE maps SET datasets=$body::json->'datasets', config=$body::jsonb->'config', info=$body::jsonb->'info' WHERE id=$escaped_id RETURNING *";
      postgres_rewrite  PUT no_changes 410;

      postgres_query    DELETE  "DELETE FROM maps WHERE id=$escaped_id";
      postgres_rewrite  DELETE  no_changes 410;
      postgres_rewrite  DELETE  changes 204;
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
