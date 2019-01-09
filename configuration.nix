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

  environment.systemPackages = with pkgs; [
    wget vim tmux htop git ripgrep unzip
    gnumake gcc libcxx libcxxabi llvm ninja clang
    python3 nodejs nodePackages.node2nix go
    firefox kmail vscode vlc
    blender godot gimp inkscape
    libreoffice
    postgresql100
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  networking.networkmanager.enable = true;
  networking.nameservers = [ "8.8.8.8" ];

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

  users.users.x = {
    isNormalUser = true;
    home = "/x";
    extraGroups = ["networkmanager"];
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql100;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE x WITH LOGIN PASSWORD 'x' CREATEDB;
      CREATE DATABASE x;
      GRANT ALL PRIVILEGES ON DATABASE x TO x;
    '';
  };

}
