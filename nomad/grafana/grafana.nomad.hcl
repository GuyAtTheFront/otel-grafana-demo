job "grafana" {
  type = "service"

  group "grafana" {
    count = 1

    network {
      # http 
      port "grafana-web" { static = 3000}
    }

    service {
      name = "grafana-web"
      address_mode = "host"
      port = "grafana-web"
      tags = ["web"]
      provider = "nomad" 
    }

    task "grafana" {
      driver = "exec"
			
      env {
        GF_SERVER_HTTP_PORT = "${ NOMAD_PORT_grafana_web }"
      }


      config {
        command = "/usr/share/grafana/bin/grafana"
        args = ["server", "--config=/etc/grafana/grafana.ini", "--homepath=/usr/share/grafana"]
      }

      resources {
        cpu    = 200
        memory = 128
      }

    }
  }
}