variable "instances" {
    type = list(object({
        name    = string
        driver  = string
        working-dir = string
    }))

    default = [
        {
            name = "loki-write-01"
            driver  = "exec"
            working-dir = ""
        },
    ]
}

job "dynamic-loki-write" {
    datacenters = ["dc1"]
    type        = "service"

    dynamic "group" {
        for_each = var.instances
        iterator = instance
        labels = ["dynamic-${instance.value.name}"]

        content {
            count = 1

            volume "nfs-nomad" {
            type = "host"
            read_only = false
            source = "nfs-nomad" # This is from client configuration file
            }

            network {
                port "http" { static = 11800}  // 3100
                port "grpc" { static = 11900 } // 9095
                port "gossip" { static = 11700 }  // 7946
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
                driver = instance.value.driver

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
    }
}