# variables {
#   otel_image = "otel/opentelemetry-collector:0.53.0"
# }

job "otel-gateway" {
#   datacenters = ["dc1"]
  type        = "service"
  node_pool = "dev"

  group "otel-gateway" {
    count = 1

    network {
	  # Prometheus
      port "metrics" { static = 28888 }

      # Receivers
      port "grpc" { static = 4317 }
	    port "http" { static = 4318	}
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