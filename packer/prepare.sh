wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
qemu-img convert -f qcow2 -O raw focal-server-cloudimg-amd64.img focal-server-cloudimg-amd64.raw
openstack image create --disk-format raw  --container-format bare --community --file focal-server-cloudimg-amd64.raw Ubuntu-Focal-20.04
openstack secret order create --name k8s_key --algorithm aes --mode cbc --bit-length 256 --payload-content-type=application/octet-stream key
#openstack secret order get http://cloud.iad1.imhcloud.net:5000/v1/orders/<key>