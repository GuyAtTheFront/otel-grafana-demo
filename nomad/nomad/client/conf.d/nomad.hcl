datacenter = "dc1"
region = "global"

data_dir = "/opt/nomad/data"
bind_addr = "146.190.92.210"

# addresses {
#   http = "0.0.0.0"
#   rpc = "0.0.0.0"
#   serf = "0.0.0.0"
# }

# advertise {
#   http = "10.15.0.7"
#   rpc = "10.15.0.7"
#   serf = "10.15.0.7"
# }

# Specifies the network ports used
# for different services required by the Nomad agent.
ports {
  http = 4646
  rpc  = 4647
  serf = 4648
}

# # Specifies the directory to use for looking up plugins
# plugin_dir = "/opt/nomad/plugins"

limits {
  https_handshake_timeout = "5s"
  http_max_conns_per_client = 200
  rpc_handshake_timeout = "5s"
  rpc_max_conns_per_client = 100
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

server {
  enabled = false
#   bootstrap_expect = 1

}

client {
  enabled = true
#   alloc_dir =
#   state_dir =
  node_class = ""
  node_pool = "default"
#   node_pool = "sit"
  min_dynamic_port = 20000
  max_dynamic_port = 32000
#   meta {
#   }
#   servers = ["206.189.37.65"]
  server_join {
    retry_join = ["206.189.37.65:4647"]
  }

  template {
    disable_file_sandbox = true
  }

  host_volume "nfs-nomad" {
    path = "/var/nfs/nomad"
    read_only = false
  }
}


consul {
  client_auto_join = false
}