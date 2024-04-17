job "otel-gateway-nginx" {
#  datacenters = ["dc1"]
  type        = "service"

  group "otel-gateway-nginx" {
    count = 1

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
        port "http" { static = 4318 }
    }

    service {
        name         = "otel-gateway-nginx"
        address_mode = "host"
        port         = "http"
        tags         = ["lb"]
        provider     = "nomad"
    }

    task "otel-gateway-nginx" {
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
            source = "/var/nfs/nomad/nginx/conf.d/nginx-otel-gateway.conf.nomad.tpl"
            destination   = "/local/nginx/conf.d/otel-gateway.conf"
            change_mode   = "signal"
            change_signal = "SIGHUP"
        }
    }
  }
}