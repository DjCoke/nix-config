{
  pkgs,
  lib,
  config,
  hostName,
  ...
}:
{
  services.k3s = {
    enable = false;
    role = "server";
    tokenFile = "/var/lib/rancher/k3s/server/token";
    extraFlags = toString (
      [
        "--write-kubeconfig-mode \"0644\""
        "--disable servicelb"
        "--disable traefik"
        "--disable local-storage"
        "--flannel-iface=ens18"
      ]
      ++ (
        if hostName == "k3s-01" then
          [
            "--node-ip=192.168.1.201"
            "--tls-san=192.168.1.250" # voor de load balancer
            "--tls-san=192.168.1.201" # k3s-01
            "--tls-san=192.168.1.202" # k3s-02
            "--tls-san=192.168.1.203" # k3s-03
          ]
        else
          [ ]
      )
    );
    # first we check of this is master-server, if so, then ClusterInit
    clusterInit = (hostName == "k3s-01");
    # id we know that clustInit = true; then this must be the master server, else server nodes
    serverAddr = if hostName != "k3s-01" then "https://192.168.1.201:6443" else "";
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

  # debugging my failures to setup my cluster
  networking.firewall.enable = false;

  # networking.firewall.allowedTCPPorts = [
  #   6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
  #   2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
  #   2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  #   10250 # k3s, metrics
  #   10255 # k3s, metrics
  # ];
  # networking.firewall.allowedUDPPorts = [
  #   8472 # k3s, flannel: required if using multi-node for inter-node networking
  # ];
}
