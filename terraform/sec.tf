resource "openstack_networking_secgroup_v2" "sec_k8s" {
  name        = "sec_k8s"
  description = "Security group for k8s defaults"
}

resource "openstack_networking_secgroup_rule_v2" "sec_rule_ssh_home" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "68.13.218.144/32"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}

resource "openstack_networking_secgroup_rule_v2" "sec_rule_vpn_gate" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "216.54.31.82/32"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}

resource "openstack_networking_secgroup_rule_v2" "sec_rule_ssh_internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = "${openstack_networking_secgroup_v2.sec_k8s.id}"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}

resource "openstack_networking_secgroup_rule_v2" "sec_rule_metricbeat" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10255
  port_range_max    = 10255
  remote_group_id   = "${openstack_networking_secgroup_v2.sec_k8s.id}"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}


resource "openstack_networking_secgroup_rule_v2" "sec_rule_weavenet_internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6783
  port_range_max    = 6783
  remote_group_id   = "${openstack_networking_secgroup_v2.sec_k8s.id}"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}
resource "openstack_networking_secgroup_rule_v2" "sec_rule_weavenet_internal_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 6783
  port_range_max    = 6784
  remote_group_id   = "${openstack_networking_secgroup_v2.sec_k8s.id}"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}



resource "openstack_networking_secgroup_rule_v2" "sec_rule_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}

resource "openstack_networking_secgroup_rule_v2" "sec_rule_kubelet_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_group_id   = "${openstack_networking_secgroup_v2.sec_k8s.id}"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}

resource "openstack_networking_secgroup_rule_v2" "sec_rule_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}
resource "openstack_networking_secgroup_rule_v2" "sec_rule_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}

resource "openstack_networking_secgroup_rule_v2" "sec_rule_prom_export" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9100
  port_range_max    = 9100
  remote_group_id   = "${openstack_networking_secgroup_v2.sec_k8s.id}"
  security_group_id = "${openstack_networking_secgroup_v2.sec_k8s.id}"
}