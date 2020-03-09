
resource "openstack_networking_network_v2" "network_k8s_nodes" {
  name           = "k8s-nodes"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_k8s_nodes" {
  network_id = "${openstack_networking_network_v2.network_k8s_nodes.id}"
  cidr       = "192.168.0.0/24"
  ip_version = 4
  dns_nameservers = ["1.1.1.1", "1.0.0.1"]
}

resource "openstack_networking_router_v2" "k8s_router" {
  name                = "k8s_router"
  external_network_id = ""
}

resource "openstack_networking_router_interface_v2" "k8s_router_interface" {
  router_id = "${openstack_networking_router_v2.k8s_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_k8s_nodes.id}"
}


resource "openstack_networking_floatingip_v2" "master_ip" {
  pool = ""
}
