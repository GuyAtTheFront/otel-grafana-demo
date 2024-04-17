# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

# Full configuration options can be found at https://developer.hashicorp.com/nomad/docs/configuration

data_dir  = "/opt/nomad/data"
bind_addr = "206.189.37.65"

addresses {
  http = "206.189.37.65"
  rpc = "206.189.37.65"
  serf = "206.189.37.65"
}

server {
  # license_path is required for Nomad Enterprise as of Nomad v1.1.1+
  #license_path = "/etc/nomad.d/license.hclic"
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
  servers = ["127.0.0.1"]

  template {
    disable_file_sandbox = true
  }

  host_volume "varlog" {
    path = "/var/log"
    read_only = false
  }

  host_volume "nginx" {
    path = "/etc/nginx"
    read_only = false
  }

  host_volume "var" {
    path = "/var"
    read_only = false
  }

  host_volume "varloki" {
    path = "/var/loki"
    read_only = false
  }

  host_volume "nfs-nomad" {
    path = "/var/nfs/nomad"
    read_only = false
  }

}