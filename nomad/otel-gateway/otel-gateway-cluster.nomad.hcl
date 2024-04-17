variables {
    lb_port = 4318
    otel_gateway_count = 1
}

job "otel-gateway-cluster" {
#   datacenters = ["dc1"]
  type        = "service"
  node_pool = "dev"

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
        port "http" { static = var.lb_port }
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

  group "otel-gateway" {
    count = var.otel_gateway_count

    constraint {
      operator = "distinct_hosts"
      value = "true"
    }

    network {
	  # Prometheus
      port "metrics" { }

      # Receivers
      port "grpc" { }
	  port "http" { }
    }

    service {
      name     = "otel-gateway"
	  address_mode = "host"
      port     = "grpc"
      tags     = ["grpc"]
      provider = "nomad"
    }

    service {
      name     = "otel-gateway"
	  address_mode = "host"
      port     = "http"
      tags     = ["http"]
      provider = "nomad"
    }

    task "otel-gateway" {
      driver = "exec"

      config {
        command = "otelcol-contrib"
        args = ["--config=local/config/otel-gateway-config.yaml"]
      }

      resources {
        cpu    = 100
        memory = 100
      }

      template {
        source = "/var/nfs/nomad/otel-gateway/conf.d/otel-gateway.conf.nomad.tpl"
        destination = "local/config/otel-gateway-config.yaml"
        change_mode = "signal" // restart
        change_signal = "SIGHUP"
      }
    }
  }
}