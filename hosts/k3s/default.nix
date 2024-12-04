#############################################################
#
#  K3s - Home Lab - Node 1
#  NixOS running on Proxmoxx VM (will be later baremetal)
#
###############################################################

{
  inputs,
  lib,
  configVars,
  configLib,
  hostName,
  ...
}:
{
  imports = lib.flatten [
    #################### Every Host Needs This ####################
    ./hardware-configuration.nix

    #################### Hardware Modules ####################
    #inputs.hardware.nixosModules.common-cpu-amd
    #inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    #################### Disk Layout ####################
    inputs.disko.nixosModules.disko
    (configLib.relativeToRoot "hosts/common/disks/standard-disk-config.nix")
    {
      _module.args = {
        disk = "/dev/sda";
        withSwap = false;
      };
    }
    (map configLib.relativeToRoot [
      #################### Required Configs ####################
      "hosts/common/core"

      #################### Host-specific Optional Configs ####################
      # "hosts/common/optional/initrd-ssh.nix"
      # "hosts/common/optional/yubikey.nix" - I do not use yubikeys
      # "hosts/common/optional/services/clamav.nix" # depends on optional/msmtp.nix TODO:
      # "hosts/common/optional/msmtp.nix" # required for emailing clamav alerts TODO:
      "hosts/common/optional/services/openssh.nix"
      "hosts/common/optional/k3s.nix"
      "hosts/common/optional/qemuguest.nix"

      # Desktop
      # "hosts/common/optional/services/greetd.nix" # display manager
      # "hosts/common/optional/hyprland.nix" # window manager
    ])
  ];

  # set custom autologin options. see greetd.nix for details
  # autoLogin.enable = true;
  # autoLogin.username = configVars.username;

  # services.gnome.gnome-keyring.enable = true;

  networking = {
    hostName = hostName;
    networkmanager.enable = true;
    enableIPv6 = false;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };
  boot.initrd = {
    systemd.enable = true;
    # This mostly mirrors what is generated on qemu from nixos-generate-config in hardware-configuration.nix
    kernelModules = [
      "xhci_pci"
      "ohci_pci"
      "ehci_pci"
      "virtio_pci"
      "ahci"
      "usbhid"
      "sr_mod"
      "virtio_blk"
      "kvm-intel"
    ];
  };

  # borg backup
  #services.backup = {
  #  enable = false;
  #  borgBackupStartTime = "01:00:00";
  #};

  # This is a fix to enable VSCode to successfully remote SSH on a client to a NixOS host
  # https://wiki.nixos.org/wiki/Visual_Studio_Code # Remote_SSH
  programs.nix-ld.enable = true;

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
