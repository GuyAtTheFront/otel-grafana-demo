job "batch" {
  datacenters = ["dc1"]

  type = "batch"

  group "batch" {
    count = 1

    task "date" {
      driver = "exec"

      config {
        command = "cat"
        args = ["local/sample.conf"]
      }

      resources {
        cpu = 100 # Mhz
        memory = 128 # MB
      }
      
      template {
        destination = "local/sample.conf"
        data = <<EOF
{{- define "printAddress" -}}
  {{- /* Args: a dictionary with 4 items */ -}}
    {{- /* serviceName: string */ -}}
    {{- /* tag: string */ -}}
    {{- /* indent: string */ -}}
    {{- /* prefix: string */ -}}
    {{- /* suffix: string */ -}}

  {{- /* Input Args */ -}}
  {{- $serviceName := sprig_get . "serviceName" -}}
  {{- $tag := sprig_get . "tag" -}}
  {{- $indent := sprig_get . "indent" -}}
  {{- $prefix := sprig_get . "prefix" -}}
  {{- $suffix := sprig_get . "suffix" -}}


  {{- if eq $indent "" }}{{ $indent = 0 }}{{ end -}}

  {{- $addrs := sprig_list -}}

  {{- if eq $tag "" -}}
    {{- range nomadService $serviceName -}}
      {{- $addrs = sprig_append $addrs (printf "%s:%d" .Address .Port) -}}
    {{- end -}}
  {{- else -}}
    {{- range nomadService $serviceName -}}
      {{- if ( .Tags | contains $tag ) -}}
        {{- $addrs = sprig_append $addrs (printf "%s:%d" .Address .Port) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- range $addrs -}}
{{ printf "%s%s%s" $prefix . $suffix | indent ($indent | sprig_int) }}
{{ end -}}
{{- end -}}

LOKI_READ
{{ $read := sprig_dict -}}
{{- $_ := sprig_set $read "serviceName" "loki-read" -}}
{{- $_ := sprig_set $read "tag" "http" -}}
{{- $_ := sprig_set $read "indent" "4" -}}
{{- $_ := sprig_set $read "prefix" "server " -}}
{{- $_ := sprig_set $read "suffix" ";" -}}

{{- template "printAddress" $read -}}

LOKI_WRITE
{{ $write := sprig_dict -}}
{{- $_ := sprig_set $write "serviceName" "loki-write" -}}
{{- $_ := sprig_set $write "tag" "http" -}}
{{- $_ := sprig_set $write "indent" "4" -}}
{{- $_ := sprig_set $write "prefix" "server " -}}
{{- $_ := sprig_set $write "suffix" ";" -}}

{{- template "printAddress" $write -}}

LOKI_BACKEND
{{ $backend := sprig_dict -}}
{{- $_ := sprig_set $backend "serviceName" "loki-backend" -}}
{{- $_ := sprig_set $backend "tag" "http" -}}
{{- $_ := sprig_set $backend "indent" "4" -}}
{{- $_ := sprig_set $backend "prefix" "server " -}}
{{- $_ := sprig_set $backend "suffix" ";" -}}

{{- template "printAddress" $backend -}}

LOKI_ALL
{{ template "printAddress" $read }}
{{- template "printAddress" $write }}
{{- template "printAddress" $backend -}}

EOF
      }
    }
  }
}

