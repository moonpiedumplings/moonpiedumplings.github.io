{
  inputs.nixpkgs.url = github:NixOS/nixpkgs;
  inputs.disko.url = github:nix-community/disko;
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, disko, ... }@attrs: {
    nixosConfigurations.hetzner-cloud = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ({ modulesPath, ... }: {
          imports = [
            (modulesPath + "/installer/scan/not-detected.nix")
            #(modulesPath + "/profiles/qemu-guest.nix") #not a qemu vm
            # try to fit the lxd-vm config in here
            #https://github.com/mrkuz/nixos/blob/c468d9772b7a84ab8e38cc4047bc83a3a443d18f/modules/nixos/virtualization/lxd-vm.nix#L4
            disko.nixosModules.disko
          ];
          disko.devices = import ./disk-config.nix {
            lib = nixpkgs.lib;
          };
          boot.loader.efi.efiSysMountPoint = "/boot/efi";
          boot.loader.grub = {
            devices = [ "nodev" ];
            efiSupport = true;
            #efiInstallAsRemovable = true;
          };
          networking = {
            usePredictableInterfaceNames = false;
            interfaces = {
              eth0 = {
                useDHCP = false;
                ipv4.addresses = [{ address = "93.92.112.130"; prefixLength = 24; }];
              };
            };
            defaultGateway = {
              interface = "eth0";
              address = "93.92.112.1";
            };
          };
          services = {
            openssh = {
              enable = true;
              settings = {
                PasswordAuthentication = false;
                #PermitRootLogin = "prohibit-password"; # this is the default
              };
              openFirewall = true;
            };
            cockpit = {
              enable = true;
              openFirewall = true;
            };
          };

          users.users.moonpie = {
            isNormalUser = true;
            extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
            #packages = with pkgs; [];
            initialHashedPassword = "$y$j9T$ZGDLrUl6VP4AiusK96/tx0$1Xb1z61RhXYR8lDlFmJkdS8zyzTnaHL6ArNQBBrEAm0"; # may replace this with a proper secret management scheme later
            openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEQDNqf12xeaYzyBFrOM2R99ciY9i0fPMdb4J64XpU3Tjv7Z5WrYx+LSLCVolzKktTfaSgaIDN8+vswixtjaAXkGW2glvTD0IwaO0N4IQloov3cLZa84I7lkj5jIkZiXJ2zHJZ8bQmayUrSj2yBwYJ61QLs+R0hpEZHfRarBU9vphykACdM6wxSj0YVkFnGlKBxZOZipW6OoKjEkFOHOSH6DYrX3V/TqALYC62iH6jEiLIycxey1vfwkywfsP9V9GlGYHutdwgAgeaN3xUnL8+X6vkQ8cbC2jEuVopodsAAArFYZLVdfAcNc17WYq5y+FX3schGpTo89SZ4Uh9gd4b45h9Hq7h6p7hBF8UCkyqSKnFiPjDJxv5yuY+rYeZ9aJSeCJUYrb1xyOreWnJkhDuYff/1NCewWL8sfuD9IC9BXWBwhxoA/OUfV9KvDBZmYoThlh86ZCQ+uqCR1DIKa1YhPMlT6gzUY01yoMj+B93RpUBUW5LqLDVCL7Qujh/0ns= moonpie@cachyos-x8664" ];
          };
          users.users.root.openssh.authorizedKeys.keys = [
            # change this to your ssh key
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCg+VqYIph1uiO243+jqdKkSOiw4hAyNWwVeIgzu7+KStY2Dji/Dzn1gu5LGj71jj/dW2Q8FpAC4WXWX5alqUJpK58HwN/d86BpnNPAxjDBOtYN2Znf3Y4108OKhEyaaKpiPSpADW5b/FW+Ki+ftMxRs9cUWuysTxoYDeX9BkTtpar5ChYaoMEkD//tUbqLx9wVFIQ4YdbVajgupUW3S2LRqCAgGBf0eTMYoZbNJHjSNlje7m9UJQOqvXJtiGdoYAqYQdHZfkCLKC1qBw6bl0ZHVkETTKr6tC89ZaZlKfZfGZqgCvyW0VzwYHwRmcOBndZgdOkEHQS/VIYmp91v1G58KMfuSBEKyUJoRVjo6lvbPHIsrGC1vNKLRiRYKGfo1lJ/qFIiq5NNfvmoYZMy+4A6jMohesTdA4yP7nwyz1o9jWmDIHeGJxZCfdYJyQ/IslesR3ACjUYAporCIk3U71f1qB7QOJAErF7+3Q6ZdOHNPPu7sURf2zMn/Q6mWktTxxU= moonpie@localhost.localdomain"
          ];
        })
      ];
    };
  };
}
