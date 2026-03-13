# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  swapDevices = [ {
    device = "/dev/disk/by-uuid/dae92de7-0851-4bab-add8-54523cf58f99";
    priority = 0; # Lower priority than zRam
  } ];
  
  zramSwap.enable = true;
  zramSwap.priority = 100; # Higher priority means use this first

  
  
  # Installs & enables mongodb
  services.mongodb.enable = true;
  services.mongodb.package = pkgs.mongodb-ce;
  systemd.services.mongodb.wantedBy = lib.mkForce [];

  #Custom
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.zsh.enable = true;
 
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IN";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable/Disable the Display manager.
  services.displayManager.cosmic-greeter.enable = true; # Cosmic greeter dm
  services.xserver.displayManager.lightdm.enable = false; # LightDM 
  
  # Enable/Disable the Desktop environment
  services.desktopManager.cosmic.enable = true ; # Cosmic DE (Wayland)
  services.xserver.desktopManager.cinnamon.enable = false; # CinnamonDE (X11)
  
  # Custom defined (For Cosmic)
  #
  # Disabled system76's default confs as they fail to preserve battery
  services.tlp = {
  enable = true;
     settings = {
     CPU_SCALING_GOVERNOR_ON_AC = "performance";
     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
     CPU_BOOST_ON_BAT = 0; # big battery win
   };
  };
  services.power-profiles-daemon.enable = false;
  services.system76-scheduler = {
    enable = true;
    settings.cfsProfiles.enable = false;
    settings.processScheduler.enable = true;
  };
  
  # Daemon (Cinnamon)
  # services.power-profiles-daemon.enable = false;
  # services.tlp.enable = true;
  
  
  
  
  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "in";
    variant = "eng";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dr460n = {
    isNormalUser = true;
    description = "Pratham";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    alacritty
    zsh
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Git configurations 
  programs.git= {
    enable = true;
    config = {
      user.name  = "dr460ngeek";
      user.email = "pratham.ag1@outlook.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  
  environment.systemPackages = with pkgs; [
	#  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  	# Development
	google-chrome
	vscode
	curl
	wget
	nodejs_24
	google-cloud-sdk
	antigravity
	git
		
	# System utility
  	xhost
	cmatrix
  	pqiv
	htop
	gedit
	neofetch
	bat
	lsd
	btop
	tree
	desktop-file-utils # Cosmic
	
	# Fonts
	nerd-fonts.fira-code # Nerd
	
	# Got "Cinnamon Dynamic Wallpaper(CDW)" working for Cinnamon DE. Also got python3 enabled better way.
	(python3.withPackages (ps: with ps; [
	  # pygobject3 # For CDW (Cinnamon)
	  # pillow # For CDW (Cinnamon)
	  # ps.python-zbar (Cinnamon)
	  
	  # Other libraries
	  
	]))
	# gobject-introspection # For CDW (Cinnamon)
	# imagemagick # For CDW (Cinnamon)
	# qrencode # For clipboard2qr (Cinnamon)
	# gtk3 # For CDW & other GTK3 related things. (Cinnamon)
	# zbar # (Cinnamon)
  ];
  
  #Enabling fingerprint sensor.
  services.fprintd = {
    enable = true;
    package = pkgs.fprintd-tod;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-broadcom;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services.flatpak.enable = true; # Enable flatpaks
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
