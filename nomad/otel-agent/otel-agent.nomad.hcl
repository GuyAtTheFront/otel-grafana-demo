job "otel-agent" {
#   datacenters = ["dc1"]
  type        = "system"

  group "otel-agent" {
    count = 1
    
    volume "logs"{
      type = "host"
      read_only = true
      source = "varlog" # This is from client configuration file
    }

    network {
	# Prometheus
      port "metrics" { static = 8889 }

      # Extensions
      # port "zpages" { static = 55679 }
      # port "health_check" { static = 13133 }
      # port "pprof" { static = 1888 }
    }

    task "otel-agent" {
      driver = "exec"
      
      volume_mount {
        volume = "logs"
        destination = "/var/log"
        read_only = true
      }

      config {
        command = "otelcol-contrib"
        args = ["--config=local/config/otel-collector-config.yaml"]
      }

      resources {
        cpu    = 128
        memory = 128
      }

      template {
        source = "/var/nfs/nomad/otel-agent/conf.d/otel-agent.conf.nomad.tpl"
        destination = "local/config/otel-collector-config.yaml"
        change_mode = "signal" // restart
        change_signal = "SIGHUP"
      }
    }
  }
}