{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

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

  environment.systemPackages = with pkgs; [
    git
    wget vim tmux htop git ripgrep unzip
    tcpdump telnet openssh
    gnumake gcc libcxx libcxxabi llvm ninja clang
    python3 nodejs nodePackages.node2nix go
    firefox kmail vscode vlc
    blender godot gimp inkscape
    libreoffice
  ];

  networking = {
     hostName = "nuc";
     networkmanager.enable = true;
     nameservers = [ "1.1.1.1" "8.8.8.8"];
     firewall = {
        allowedTCPPortRanges = [
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
    webroot = "/d/challenges";
    email = "ingenieroariel@gmail.com";
  };
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
        title varchar(255) NOT NULL,
        data jsonb NOT NULL,
        metadata jsonb NOT NULL,
        created_at timestamp DEFAULT current_timestamp
      );

      INSERT INTO maps(title, data, metadata) VALUES (
          'one', 
          '{ "layers": [] }'::jsonb,
          '{ "contact": { "phone": "555-5555" } }'::jsonb
      ); 
    '';
};

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
      listen 443 ssl;
      server_name *.puerti.co;
      ssl_certificate /var/lib/acme/puerti.co/fullchain.pem;
      ssl_certificate_key /var/lib/acme/puerti.co/key.pem;
 
      root "/d/puerti.co";

      location / {
        default_type text/plain;
        content_by_lua_block {
          ngx.say('puertico is an experiment on geospatial data sharing')
        }
      }

    location /maps {
      postgres_pass database;
      rds_json on;
      postgres_query    HEAD GET  "SELECT * FROM maps";
      
      postgres_escape $title $arg_title;
      postgres_escape $body  $arg_body;
      postgres_query
        POST "INSERT INTO maps (title, body) VALUES($title, $body) RETURNING *";
      postgres_rewrite  POST changes 201;
    }

    location ~ /maps/(?<id>\d+) {
      postgres_pass database;
      rds_json  on;
      postgres_escape $escaped_id $id;
      postgres_query    HEAD GET  "SELECT * FROM maps WHERE id=$escaped_id";
      postgres_rewrite  HEAD GET  no_rows 410;

      postgres_escape $title $arg_title;
      postgres_escape $body  $arg_body;
      postgres_query
        PUT "UPDATE maps SET title=$title, body=$body WHERE id=$escaped_id RETURNING *";
      postgres_rewrite  PUT no_changes 410;

      postgres_query    DELETE  "DELETE FROM maps WHERE id=$escaped_id";
      postgres_rewrite  DELETE  no_changes 410;
      postgres_rewrite  DELETE  changes 204;
    }


      location /secure {
       default_type text/plain;
       content_by_lua_block {
         ngx.say('Secure area.')
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

       location /auth/ {
         default_type text/plain;
         content_by_lua_block {
            ngx.say('Please log in')
         }
       }
     }
    }
 
 '';

};

}
