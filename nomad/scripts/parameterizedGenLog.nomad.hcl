job "parameterizedGenLogs" {
  datacenters = ["dc1"]
  type = "batch"
  node_pool = "default"

  parameterized {
    payload = "forbidden"
    meta_optional = ["LOG_LEVEL", "LOG_MESSAGE"]
  }

  group "parameterizedGenLogs" {
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


    task "genlogs" {
      driver = "exec"
      
        volume_mount {
            volume = "nfs-nomad"
            destination = "/var/nfs/nomad/"
            read_only = false
        }
      
      volume_mount {
            volume = "var"
            destination = "/var"
            read_only = false
        }

      config {
        command = "bash"
        args = ["/var/nfs/nomad/scripts/genlogs.sh", "${NOMAD_META_LOG_LEVEL}", "${NOMAD_META_LOG_MESSAGE}"]
      }

      resources {
        cpu = 100 # Mhz
        memory = 128 # MB
      }
    }
  }
}

