# kubeadm-ubuntu

Packer image that just has the essentials for kubeadm ready. 

Image ID: 6520b1b6-8987-4ce6-9d54-b1d229ce11c3

```
[   18.930659] cloud-init[965]: Cloud-init v. 19.2-24-ge7881d5c-0ubuntu1~18.04.1 running 'modules:config' at Mon, 16 Sep 2019 06:47:16 +0000. Up 18.07 seconds.
[[0;32m  OK  [0m] Started Apply the settings specified in cloud-config.
         Starting Execute cloud user/final scripts...
[   19.948091] cloud-init[1037]: [preflight] Running pre-flight checks
[   20.427660] cloud-init[1037]: [preflight] Reading configuration from the cluster...
[   20.431392] cloud-init[1037]: [preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
[[0;32m  OK  [0m] Stopped kubelet: The Kubernetes Node Agent.
[   21.002179] cloud-init[1037]: [kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.15" ConfigMap in the kube-system namespace
[   21.014965] cloud-init[1037]: [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[   21.018823] cloud-init[1037]: [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[   21.031758] cloud-init[1037]: [kubelet-start] Activating the kubelet service
[[0;32m  OK  [0m] Started kubelet: The Kubernetes Node Agent.
[   21.193770] cloud-init[1037]: [kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

Ubuntu 18.04.3 LTS worker-3-packer-test ttyS0

worker-3-packer-test login: [   35.779517] cloud-init[1037]: This node has joined the cluster:
[   35.783330] cloud-init[1037]: * Certificate signing request was sent to apiserver and a response was received.
[   35.787723] cloud-init[1037]: * The Kubelet was informed of the new secure connection details.
[   35.791097] cloud-init[1037]: Run 'kubectl get nodes' on the control-plane to see this node join the cluster.ci-info: ++++++++++Authorized keys from /home/ubuntu/.ssh/authorized_keys for user ubuntu+++++++++++
ci-info: +---------+-------------------------------------------------+---------+---------------
```

```
  Ready                True    Mon, 16 Sep 2019 06:49:24 +0000   Mon, 16 Sep 2019 06:47:54 +0000   KubeletReady                 kubelet is posting ready status. AppArmor enabled
```

Openstack makes a kubeadm worker using a packer image and has it join my cluster using via userdatata in 35 seconds and posts ready status in ~ 55 seconds. 

Todo

- [ ] Sample user-data with cloud.conf
- [ ] Sample `openstack loadbalancer create` command
- [ ] Sample `openstack server create` commands with workers using no volumes 
- [ ] A tidy bash script that does all of the above
- [ ] A pretty hugo github page
