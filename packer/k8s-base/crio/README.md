# Making
- Modify configs if needed
- Change config.json settings: Your network/base image etc

Within `/packer/k8s-base/crio` with OS envs set:
```
packer build .\config.json
```

# Preparing
https://github.com/kubernetes/cloud-provider-openstack/blob/master/docs/using-controller-manager-with-kubeadm.md