#!/bin/sh

set -e

#General update / upgrade
sudo apt update -y 
sudo apt upgrade -y

#install tools required to build
sudo apt-get install -y git golang-go libbtrfs-dev libassuan-dev libdevmapper-dev   libglib2.0-dev   libc6-dev   libgpgme11-dev   libgpg-error-dev   libseccomp-dev   libsystemd-dev   libselinux1-dev   pkg-config   go-md2man   libudev-dev   software-properties-common   gcc   make ipset


mkdir work
export GOPATH=/home/ubuntu/work

#Make/Install runc
go get github.com/opencontainers/runc
cd $GOPATH/src/github.com/opencontainers/runc
make BUILDTAGS='seccomp apparmor ambient'
sudo make install
cd ~

#Install CRIO
git clone https://github.com/cri-o/cri-o.git
cd cri-o
git checkout release-1.17
make BUILDTAGS='seccomp apparmor'
sudo make install
sudo make install.config
sudo mv /tmp/crio.conf /etc/crio/crio.conf
sudo mkdir -p /etc/containers
sudo mv /tmp/policy.json /etc/containers/policy.json
sudo make install.systemd
sudo systemctl enable crio
sudo mkdir -p /usr/share/containers/oci/hooks.d
sudo chown root:root /etc/crio/crio.conf
sudo chown root:root /etc/containers

cd ..

#Install CNI
wget -q https://github.com/containernetworking/plugins/releases/download/v0.8.5/cni-plugins-linux-amd64-v0.8.5.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -xvf cni-plugins-linux-amd64-v0.8.5.tgz -C /opt/cni/bin/

#Install runsc
wget -q https://storage.googleapis.com/gvisor/releases/nightly/latest/runsc
sudo chmod a+x runsc
sudo mv runsc /usr/local/bin

#Make/Install conmon
git clone https://github.com/containers/conmon.git
cd conmon
make
sudo make install
cd ..

#Install kubernetes
sudo su <<HERE
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo br_netfilter >> /etc/modules
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo '1' > /proc/sys/net/ipv4/ip_forward
modprobe br_netfilter
mv /tmp/kubelet /etc/default/kubelet
HERE

#Move configs
sudo mkdir -p /etc/kubernetes/manifests
sudo mv /tmp/cloud-config /etc/kubernetes/cloud-config
sudo mv /tmp/barbican.yaml /etc/kubernetes/manifests/barbican.yaml
sudo mv /tmp/encryption-config.yaml /etc/kubernetes/encryption-config.yaml
sudo chown -R root:root /etc/kubernetes


#Cleanup
sudo apt remove -y git golang-go libassuan-dev libbtrfs-dev libdevmapper-dev   libglib2.0-dev   libc6-dev   libgpgme11-dev   libgpg-error-dev   libseccomp-dev   libsystemd-dev   libselinux1-dev   pkg-config   go-md2man   libudev-dev   software-properties-common   gcc   make
rm -rf conmon
sudo rm -rf cri-o
sudo rm -rf work
rm -rf cni-plugins-linux-amd64-v0.8.5.tgz



#Prepull images
sudo systemctl start crio
sudo kubeadm config images pull
