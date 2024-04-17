upstream otel_gateway {
{{ range nomadService "otel-gateway" }}
  {{ if .Tags | contains "http" }}
  server {{ .Address }}:{{ .Port }};
  {{ end }}
{{ else }}server 127.0.0.1:65535; # force a 502
{{ end }}
}

server {
   listen 4318;

   location / {
      proxy_pass http://otel_gateway;
   }
}