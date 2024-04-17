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

{{ $LOKI_READ := "loki-read" }}
{{ $LOKI_WRITE := "loki-write" }}
{{ $LOKI_BACKEND := "loki-backend" }}

{{- /* LOKI_READ */ -}}
{{ $read := sprig_dict -}}
{{- $_ := sprig_set $read "serviceName" $LOKI_READ -}}
{{- $_ := sprig_set $read "tag" "http" -}}
{{- $_ := sprig_set $read "indent" "4" -}}
{{- $_ := sprig_set $read "prefix" "server " -}}
{{- $_ := sprig_set $read "suffix" ";" -}}

{{- /* LOKI_WRITE */ -}}
{{ $write := sprig_dict -}}
{{- $_ := sprig_set $write "serviceName" $LOKI_WRITE -}}
{{- $_ := sprig_set $write "tag" "http" -}}
{{- $_ := sprig_set $write "indent" "4" -}}
{{- $_ := sprig_set $write "prefix" "server " -}}
{{- $_ := sprig_set $write "suffix" ";" -}}

{{- /* LOKI_BACKEND */ -}}
{{ $backend := sprig_dict -}}
{{- $_ := sprig_set $backend "serviceName" $LOKI_BACKEND -}}
{{- $_ := sprig_set $backend "tag" "http" -}}
{{- $_ := sprig_set $backend "indent" "4" -}}
{{- $_ := sprig_set $backend "prefix" "server " -}}
{{- $_ := sprig_set $backend "suffix" ";" -}}

{{- if nomadService $LOKI_READ -}}
upstream loki-read {
{{ template "printAddress" $read -}}
}
{{- end}}

{{- if nomadService $LOKI_WRITE -}}
upstream loki-write {
{{ template "printAddress" $write -}}
}
{{- end}}

{{- if nomadService $LOKI_BACKEND -}}
upstream loki-backend {
{{ template "printAddress" $backend -}}
}
{{- end}}

upstream loki-any {
{{ template "printAddress" $read }}
{{- template "printAddress" $write }}
{{- template "printAddress" $backend -}}
}

server {
    listen 80;
    listen 3100;
    
    # ------------------------------------
    # endpoints exposed by all components
    # ------------------------------------

    location = /ready {
        proxy_pass    http://loki-any$request_uri;
    }

    location = /log_level {
        proxy_pass    http://loki-any$request_uri;
    }

    location = /metrics {
        proxy_pass    http://loki-any$request_uri;
    }

    location = /config {
        proxy_pass    http://loki-any$request_uri;
    }

    location = /services {
        proxy_pass    http://loki-any$request_uri;
    }

    location = /loki/api/v1/status/buildinfo {
        proxy_pass    http://loki-any$request_uri;
    }

    location = /loki/api/v1/format_query {
        proxy_pass    http://loki-any$request_uri;
    }

    # -----------------
    #  READ components
    # -----------------

    # endpoints exposed by querier and query frontend

    location = /loki/api/v1/query {
        proxy_pass    http://loki-read$request_uri;
    }

    location = /loki/api/v1/query_range {
        proxy_pass    http://loki-read$request_uri;
    }
    
    location = /loki/api/v1/labels {
        proxy_pass    http://loki-read$request_uri;
    }

    location ~ /loki/api/v1/label/.*/values {
        proxy_pass    http://loki-read$request_uri;
    }

    location = /loki/api/v1/series {
        proxy_pass    http://loki-read$request_uri;
    }

    location = /loki/api/v1/index/stats {
        proxy_pass    http://loki-read$request_uri;
    }

    location = /loki/api/v1/index/volume {
        proxy_pass    http://loki-read$request_uri;
    }

    location = /loki/api/v1/index/volume_range {
        proxy_pass    http://loki-read$request_uri;
    }


    # WebSocket endpoint
    location = /loki/api/v1/tail {
        proxy_pass    http://loki-read$request_uri;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # ------------------
    #  WRITE components
    # ------------------

    # endpoints exposed by distributor

    location = /loki/api/v1/push {
        proxy_pass http://loki-write$request_uri;
    }

    location =  /distributor/ring {
        proxy_pass http://loki-write$request_uri;
    }


    # endpoints exposed by ingester

    location = /flush {
        proxy_pass http://loki-write$request_uri;
    }

    location = /ingester/shutdown {
        proxy_pass http://loki-write$request_uri;
    }


    # --------------------
    #  BACKEND components
    # --------------------

    # endpoints exposed by ruler
    location =  /ruler/ring {
        proxy_pass http://loki-backend$request_uri;
    }

    location =  /loki/api/v1/rules {
        proxy_pass http://loki-backend$request_uri;
    }

    # GET /loki/api/v1/rules/{namespace}
    # {namespace} matches one-or-more characters that are not (\r, \n, /)
    location ~ ^\/loki\/api\/v1\/rules\/[^\/\r\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }

    # GET /loki/api/v1/rules/{namespace}/{groupName}
    # {namespace} and {groupName} matches one-or-more characters that are not (\r, \n, /)
    location ~ ^\/loki\/api\/v1\/rules\/[^\/\r?\n]+\/[^\/\r?\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }
    
    # POST /loki/api/v1/rules/{namespace}
    # {namespace} matches one-or-more characters that are not (\r, \n, /)
    location ~ ^\/loki\/api\/v1\/rules\/[^\/\r\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }

    # DELETE /loki/api/v1/rules/{namespace}/{groupName}
    # {namespace} and {groupName} matches one-or-more characters that are not (\r, \n, /)
    location ~ ^\/loki\/api\/v1\/rules\/[^\/\r?\n]+\/[^\/\r?\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }

    # DELETE /loki/api/v1/rules/{namespace}
    # {namespace} matches one-or-more characters that are not (\r, \n, /)
    location ~ ^\/loki\/api\/v1\/rules\/[^\/\r\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }
    
    location = /api/prom/rules {
        proxy_pass http://loki-backend$request_uri;
    }

    # GET /api/prom/rules/{namespace}
    # {namespace} matches one-or-more characters that are not (\r, \n, /)
    location ~  ^\/api\/prom\/rules\/[^\/\r?\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }

    # GET /api/prom/rules/{namespace}/{groupName}
    # {namespace} and {groupName} matches one-or-more characters that are not (\r, \n, /)
    location ~ ^\/api\/prom\/rules\/[^\/\r?\n]+\/[^\/\r?\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }

    # POST /api/prom/rules/{namespace}
    # {namespace} matches one-or-more characters that are not (\r, \n, /)
    location ~ ^\/api\/prom\/rules\/[^\/\r?\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }

    # DELETE /api/prom/rules/{namespace}/{groupName}
    # {namespace} and {groupName} matches one-or-more characters that are not (\r, \n, /)
    location ~ ^\/api\/prom\/rules\/[^\/\r?\n]+\/[^\/\r?\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }

    # DELETE /api/prom/rules/{namespace}
    # {namespace} matches one-or-more characters that are not (\r, \n, /)
    location ~ ^\/api\/prom\/rules\/[^\/\r?\n]+$ {
        proxy_pass http://loki-backend$request_uri;
    }

    location = /prometheus/api/v1/rules {
        proxy_pass http://loki-backend$request_uri;
    }

    location = /prometheus/api/v1/alerts {
        proxy_pass http://loki-backend$request_uri;
    }
    

    # endpoints exposed by compactor
    location = /compactor/ring  {
        proxy_pass http://loki-backend$request_uri;
    }

    location = /loki/api/v1/delete {
        proxy_pass http://loki-backend$request_uri;
    }

# TODO: Add http type
#     location = /loki/api/v1/delete {
#         proxy_pass http://loki-backend$request_uri;
#    }

#     location = /loki/api/v1/delete {
#         proxy_pass http://loki-backend$request_uri;
#     }

    
}

