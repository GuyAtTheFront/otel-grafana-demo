job "loki-backend" {
  datacenters = ["dc1"]
  type = "service"
  node_pool = "default"

  # Read
  group "loki-backend" {
    count = 1
    
    volume "nfs-nomad" {
        type = "host"
        read_only = false
        source = "nfs-nomad" # This is from client configuration file
    }
    
    network {
      port "http" { static = 12800}  // 3100
      port "grpc" { static = 12900 } // 9095
      port "gossip" { static = 12700 }  // 7946
      # port "lb" { static = 8080 }
    }

    service {
      name = "loki-backend"
      address_mode = "host"
      port = "http"
      tags = ["http"]
      provider = "nomad"
    }

    service {
      name = "loki-backend"
      address_mode = "host"
      port = "grpc"
      tags = ["grpc"]
      provider = "nomad"
    }

    service {
      name = "loki-backend"
      address_mode = "host"
      port = "gossip"
      tags = ["gossip"]
      provider = "nomad"
    }

    task "loki-backend" {
      driver = "exec"
      
      volume_mount {
        volume = "nfs-nomad"
        destination = "/var/nfs/nomad/"
        read_only = false
      }

      config {
        command = "/usr/bin/loki"
        args = [
          "-target=backend", 
          "-config.file=local/loki/config.yaml", 
          "-legacy-read-mode=false",
          "-log.level=debug",
          ]
      }

      resources {
        cpu = 100
        memory = 128
      }

      template {
        source = "/var/nfs/nomad/loki/conf.d/loki.conf.nomad.tpl"
        destination = "local/loki/config.yaml"
        change_mode = "restart" // restart
        # change_signal = "SIGHUP"
      }
    }
  }


}