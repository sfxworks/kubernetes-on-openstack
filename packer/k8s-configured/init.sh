#!/bin/sh

set -e
sudo mkdir -p /etc/kubernetes
sudo mkdir -p /var/lib/kubelet
sudo mv cloud-config /etc/kubernetes
sudo mv kubelet-extra-args.env /etc/default/kubelet
sudo systemctl daemon-reload