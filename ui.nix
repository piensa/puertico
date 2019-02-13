{ ... }:

{
services.xserver.enable = true;		
services.xserver.displayManager.sddm.enable = true;		
services.xserver.displayManager.sddm.autoLogin.enable = true;		
services.xserver.displayManager.sddm.autoLogin.user = "x";		
services.xserver.desktopManager.plasma5.enable = true;		

sound.enable = true;		
hardware.pulseaudio.enable = true;		
hardware.bluetooth.enable = true;
}
