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

 nixpkgs.config.packageOverrides = pkgs:
 {
  nginx = pkgs.nginx.override {
    modules = [
      pkgs.nginxModules.lua
      pkgs.nginxModules.dav
      pkgs.nginxModules.moreheaders
    ];
  };
 };

services.nginx = {
  enable = true;
  package = pkgs.nginx;
  config = ''
  events {
    worker_connections  4096;
  }
  http {
    include       ${pkgs.nginx}/conf/mime.types;
    default_type  application/octet-stream;

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

      location /secure {
       default_type text/plain;
       content_by_lua_block {
         ngx.say('Secure area.')
       }

       access_by_lua_block {
         -- Some variable declarations.
         local cookie = ngx.var.cookie_MyToken
         local hmac = ""
         local timestamp = ""
 
         -- Check that the cookie exists.
         if cookie ~= nil and cookie:find(":") ~= nil then
           -- If there's a cookie, split off the HMAC signature
           -- and timestamp.
           local divider = cookie:find(":")
           hmac = cookie:sub(divider+1)
           timestamp = cookie:sub(0, divider-1)

           -- Verify that the signature is valid.
           if hmac_sha1("some very secret string", timestamp) == hmac and tonumber(timestamp) >= os.time() then
             return
           end
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

security.acme.certs = {
  "puerti.co" = {
    webroot = "/d/challenges";
    email = "ingenieroariel@gmail.com";
  };
};

}
