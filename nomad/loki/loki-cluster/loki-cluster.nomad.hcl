variables {
    loki_read_count = 1
    loki_write_count = 1
}

job "loki-cluster" {
#  datacenters = ["dc1"]
  type        = "service"
  node_pool   = "all"

  group "loki-lb" {
    count = 1

    # constraint {}

    volume "nfs-nomad" {
        type = "host"
        read_only = false
        source = "nfs-nomad" # This is from client configuration file
    }

    volume "var" {
        type = "host"
        read_only = false
        source = "var"
    }

    network {
        port "http" { static = 3100 }
    }

    service {
        name         = "loki-nginx"
        address_mode = "host"
        port         = "http"
        tags         = []
        provider     = "nomad"
    }

    task "nginx" {
        driver = "exec"

        volume_mount {
            volume = "var"
            destination = "/var"
            read_only = false
        }

        volume_mount {
            volume = "nfs-nomad"
            destination = "/var/nfs/nomad/"
            read_only = false
        }

        config {
            command = "/usr/sbin/nginx"
            args = [
                "-c", "/etc/nginx/nginx.conf", 
                "-g", "daemon off;"
                ]
        }

        resources {
            cpu    = 100
            memory = 100
        }

        template {
            source = "/var/nfs/nomad/nginx/conf.d/nginx-loki.conf.nomad.tpl"
            destination   = "/local/nginx/conf.d/loki.conf"
            change_mode   = "signal"
            change_signal = "SIGHUP"
        }
    }
  }

  group "loki-read" {
    count = var.loki_read_count

    constraint {
        operator = "distinct_hosts"
        value = "true"
    }
    
    volume "nfs-nomad" {
        type = "host"
        read_only = false
        source = "nfs-nomad" # This is from client configuration file
    }

    # For debugging, best to set ports to static
    # Recommend port sematics:
      # 5-digits port number, to avoid collision with other applciations
      # first digit = instance number, (instance 1 = 1, instance 2 = 2 ... )
      # second digit = instance type, (read = 0, write = 1, backend = 2)
      # third digit = port type, (7 = gossip, 8 = http, 9 = grpc)
      # fourth and fifth digits = 0
        # so.. HTTP port of 3rd instance of Write node = 31800
    network {
      port "http" {}  // 3100, 10800 
      port "grpc" {} // 9095, 10900 
      port "gossip" {}  // 7946, 10700
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

  group "loki-write" {
    count = var.loki_write_count

    constraint {
        operator = "distinct_hosts"
        value = "true"
    }

    volume "nfs-nomad" {
        type = "host"
        read_only = false
        source = "nfs-nomad" # This is from client configuration file
    }

    network {
        port "http" {}  // 3100, 11800
        port "grpc" {} // 9095, 11900
        port "gossip" {}  // 7946, 11700
        # port "lb" { static = 8080 }
    }
    
    service {
        name = "loki-write"
        address_mode = "host"
        port = "http"
        tags = ["http"]
        provider = "nomad"
    }

    service {
        name = "loki-write"
        address_mode = "host"
        port = "grpc"
        tags = ["grpc"]
        provider = "nomad"
    }

    service {
        name = "loki-write"
        address_mode = "host"
        port = "gossip"
        tags = ["gossip"]
        provider = "nomad"
    }

    task "loki-write" {
        driver = "exec"

        volume_mount {
            volume = "nfs-nomad"
            destination = "/var/nfs/nomad/"
            read_only = false
        }

        config {
            command = "/usr/bin/loki"
            args = [
            "-target=write", 
            "-config.file=local/loki/config.yaml", 
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

  group "loki-backend" {
    count = 1
    
    volume "nfs-nomad" {
        type = "host"
        read_only = false
        source = "nfs-nomad" # This is from client configuration file
    }
    
    network {
      port "http" {}  // 3100, 12800
      port "grpc" {} // 9095, 12900
      port "gossip" {}  // 7946, 12700
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