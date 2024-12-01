{
  pkgs,
  lib,
  config,
  hostName,
  ...
}:
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = "/var/lib/rancher/k3s/server/token";
    extraFlags = toString ([
      "--write-kubeconfig-mode \"0644\""
      "--disable servicelb"
      "--disable traefik"
      "--disable local-storage"
      #  "--flannel-iface=ens18"
    ]
    # ++ (
    #   if hostName == "k3s-01" then
    #     [ ]
    #   else
    #     [
    #       "--server-ip 192.168.1.145"
    #     ]
    # )
    );
    # first we check of this is master-server, if so, then ClusterInit
    clusterInit = (hostName == "k3s-01");
    # id we know that clustInit = true; then this must be the master server, else server nodes
    serverAddr = if hostName != "k3s-01" then "https://192.168.1.145:6443" else "";
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
