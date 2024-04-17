job "loki-read" {
  datacenters = ["dc1"]
  type = "service"
  node_pool = "default"

  # Read
  group "loki-read" {
    count = 1
    
    volume "nfs-nomad" {
        type = "host"
        read_only = false
        source = "nfs-nomad" # This is from client configuration file
    }

    network {
      port "http" { static = 10800}  // 3100
      port "grpc" { static = 10900 } // 9095
      port "gossip" { static = 10700 }  // 7946
      # port "lb" { static = 8080 }
    }

    service {
      name = "loki-read"
      address_mode = "host"
      port = "http"
      tags = ["http"]
      provider = "nomad"
    }

    service {
      name = "loki-read"
      address_mode = "host"
      port = "grpc"
      tags = ["grpc"]
      provider = "nomad"
    }

    service {
      name = "loki-read"
      address_mode = "host"
      port = "gossip"
      tags = ["gossip"]
      provider = "nomad"
    }

    task "loki-read" {
      driver = "exec"
      
      volume_mount {
        volume = "nfs-nomad"
        destination = "/var/nfs/nomad/"
        read_only = false
      }

      config {
        command = "/usr/bin/loki"
        args = [
          "-target=read", 
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