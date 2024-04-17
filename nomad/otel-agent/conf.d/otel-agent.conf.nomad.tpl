receivers:
  filelog:
    include: [/var/log/app/sample-json.log]
    start_at: beginning
    operators:
      - type: json_parser
        timestamp:
          parse_from: attributes.timestamp
          layout: '%Y-%m-%dT%H:%M:%S.%L'  
        severity:
          parse_from: attributes.level

    resource:
      resource1: os.name
        # need to get hostname into attributes

    attributes:
      attribute1: value1
      attribtue2: value2
        
processors:

  attributes:
    actions:
      - action: insert
        key: loki.attribute.labels
        value: [log.file.name, attribute1]

  batch:
        

exporters:
  otlphttp:
    endpoint: "http://{{with nomadService "otel-gateway-nginx"}}{{with index . 0}}{{.Address}}:{{.Port}}{{end}}{{end}}"

  debug:

service:
  telemetry:
    metrics:
      address: 0.0.0.0:{{ env "NOMAD_PORT_metrics" }}
  pipelines:
    logs:
      receivers: [filelog]
      processors: [attributes]
      exporters: [debug, otlphttp]