#!/bin/sh

set -e

sudo su <<HERE

#install kubernetes

apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

#install containerd

sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /etc/containerd

wget https://github.com/containernetworking/plugins/releases/download/v0.8.1/cni-plugins-linux-amd64-v0.8.1.tgz
wget https://github.com/containerd/containerd/releases/download/v1.3.0-beta.0/containerd-1.3.0-beta.0.linux-amd64.tar.gz
wget https://storage.googleapis.com/gvisor/releases/nightly/latest/runsc
wget https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64

mv runc.amd64 /usr/bin/runc
chmod +x /usr/bin/runc

mv runsc /usr/local/bin/runsc
chmod +x /usr/local/bin/runsc

cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target
[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
[Install]
WantedBy=multi-user.target
EOF

tar -xvf cni-plugins-linux-amd64-v0.8.1.tgz -C /opt/cni/bin/
tar -xvf containerd-1.3.0-beta.0.linux-amd64.tar.gz -C /


#install gvisor-containerd-shim
wget  -O gvisor-containerd-shim https://github.com/google/gvisor-containerd-shim/releases/download/v0.0.3/gvisor-containerd-shim.linux-amd64
chmod +x gvisor-containerd-shim
sudo mv gvisor-containerd-shim /usr/local/bin/gvisor-containerd-shim

#configure containerd
cat <<EOF | sudo tee /etc/containerd/gvisor-containerd-shim.toml
# This is the path to the default runc containerd-shim.
runc_shim = "/usr/local/bin/containerd-shim"
EOF

cat <<EOF | sudo tee /etc/containerd/config.toml
disabled_plugins = ["restart"]
[plugins.linux]
  shim = "/usr/local/bin/gvisor-containerd-shim"
  shim_debug = true
[plugins.cri.containerd.runtimes.runsc]
  runtime_type = "io.containerd.runtime.v1.linux"
  runtime_engine = "/usr/local/bin/runsc"
  runtime_root = "/run/containerd/runsc"
EOF


echo br_netfilter >> /etc/modules
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo '1' > /proc/sys/net/ipv4/ip_forward
modprobe br_netfilter


systemctl enable kubelet
systemctl enable containerd

systemctl start containerd
swapoff -a

apt-get install -y ipset 

kubeadm config images pull --cri-socket=/var/run/containerd/containerd.sock
HERE
