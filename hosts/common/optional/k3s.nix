{ pkgs, lib, config, hostName, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = "/var/lib/rancher/k3s/server/token";
    extraFlags = toString (
      [
        "--write-kubeconfig-mode \"0644\""
        "--cluster-init"
        "--disable servicelb"
        "--disable traefik"
        "--disable local-storage"
        "--flannel-iface=ens18"
      ]
      ++ (
        if hostName == "k3s-01" then
          [ ]
        else
          [
            "--server https://k3s-01:6443"
          ]
      )
    );
    clusterInit = (hostName == "k3s-01");
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${hostName}";
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      k3s
      cifs-utils
      nfs-utils
      ;
  };
}
