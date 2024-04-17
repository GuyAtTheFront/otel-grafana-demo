{{- $loki_lb_addr := "" -}}
{{- with nomadService "loki-nginx" -}}
    {{- with index . 0 -}}
        {{- $loki_lb_addr = printf "%s:%d" .Address .Port -}}
    {{- end -}}
{{- end -}}
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: {{env "NOMAD_ADDR_grpc"}}
      http:
        endpoint: {{env "NOMAD_ADDR_http"}}
        
processors:
  batch:
        
exporters:
  loki:
    endpoint: "http://{{$loki_lb_addr}}/loki/api/v1/push"
   
  debug:

service:
  telemetry:
    metrics:
      address: 0.0.0.0:{{ env "NOMAD_PORT_metrics" }}
  pipelines:
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug, loki]