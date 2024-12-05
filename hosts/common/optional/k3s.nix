{
  pkgs,
  lib,
  config,
  hostName,
  ...
}:
{
  services.k3s =
    if
      builtins.elem hostName [
        "k3s-01"
        "k3s-02"
        "k3s-03"
      ]
    then
      {
        enable = true;
        role = "server";
        tokenFile = "/var/lib/rancher/k3s/server/token";
        extraFlags = toString (
          [
            "--write-kubeconfig-mode \"0644\""
            "--disable servicelb"
            "--disable traefik"
            "--disable local-storage"
            "--flannel-iface=ens18"
            "--node-taint node-role.kubernetes.io/master=true:NoSchedule"
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
      }
    else
      {
        enable = true;
        role = "agent";
        serverAddr = "https://192.168.1.250:6443"; # Verbind met Kube-VIP
        tokenFile = "/var/lib/rancher/k3s/server/token";
        extraFlags = toString [
          "--node-ip=192.168.1.2${builtins.substring 4 2 hostName}" # Automatisch IP bepalen
          "--node-label \"longhorn=true\""
          (
            if
              builtins.elem hostName [
                "k3s-04"
                "k3s-05"
                "k3s-06"
              ]
            then
              "--node-label \"worker=true\""
            else
              ""
          )
        ];
      };

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${hostName}";
  };

  # Fixes for longhorn
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  virtualisation.docker = {
    enable = true;
    logDriver = "json-file";
  };
  boot.kernelModules = [ "dm_crypt" ];

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      k3s
      cifs-utils
      nfs-utils
      kubernetes-helm
      helmfile
      ;
  };

  # debugging my failures to setup my cluster
  networking.firewall.enable = false;

  # networking.firewall.allowedTCPPorts = [
  #   7946 # flannel
  #   8285 # flannel
  #   8472 # flannel
  #
  #   # Kubernetes
  #   2379 # etcd-client
  #   2380 # etcd-cluster
  #   6443 # kube-apiserver
  #
  #   # Prometheus metrics
  #   10250
  #   10254
  # ];
  # networking.firewall.allowedUDPPorts = [
  #   7946 # flannel
  #   8472 # flannel
  # ];

}
