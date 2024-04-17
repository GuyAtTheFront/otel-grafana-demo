{{- $ROOT_DATA_DIR := "/var/nfs/nomad/loki" -}}

{{- $instanceName := printf "%s-%s" ( env "NOMAD_TASK_NAME" ) ( env "NOMAD_ALLOC_INDEX" ) -}}

{{- $sharedDataDir := printf "%s%s" $ROOT_DATA_DIR "/data/shared" -}}
{{- $instanceDataDir := printf "%s%s%s" $ROOT_DATA_DIR "/data/" $instanceName -}}


{{- /* -------------- */ -}}
{{- /*  Paths Config   */ -}}
{{- /* -------------- */ -}}

{{- /* Shared Resource */ -}}
  {{- /* Write */ -}}
    {{- $storage_config__filesystem__directory := printf "%s%s" $sharedDataDir "/chunks" -}}
  
  {{- /* Backend */ -}}
    {{- $storage_config__boltdb_shipper__cache_location := printf "%s%s" $sharedDataDir "/tsdb-shipper-cache" -}}
    {{- $ruler__storage__local__directory := printf "%s%s" $sharedDataDir "/rules" -}}
    {{- $ruler__rule_path := printf "%s%s" $sharedDataDir "/rules" -}}

{{- /* Instance Resource */ -}}
  {{- /* Write */ -}}
    {{- $storage_config__tsdb_shipper__active_index_directory := printf "%s%s" $instanceDataDir "/tsdb-shipper-active" -}}
    {{- $ingester__wal__dir := printf "%s%s" $instanceDataDir "/ingester-wal" -}}
    {{- $ingester__wal__shutdown_marker_path := printf "%s%s" $instanceDataDir "/shutdown-marker" -}}

  {{- /* Backend */ -}}
    {{- $compactor__working_directory := printf "%s%s" $instanceDataDir "/compactor" -}}
    {{- $ruler__wal__dir := printf "%s%s" $instanceDataDir "/ruler-wal" -}}

{{- /* ---------------- */ -}}
{{- /*  Network Config  */ -}}
{{- /* ---------------- */ -}}

{{- $LOKI_READ := "loki-read" -}}
{{- $LOKI_WRITE := "loki-write" -}}
{{- $LOKI_BACKEND := "loki-backend" -}}

{{- $backendHttpAddress := "" -}}
{{- $backendGrpcAddress := "" -}}

{{- range nomadService $LOKI_BACKEND -}}
  {{- if .Tags | contains "http" -}}
    {{- $backendHttpAddress = printf "%s:%d" .Address .Port -}}
  {{- end -}}
    {{- if .Tags | contains "grpc" -}}
  {{- $backendGrpcAddress = printf "%s:%d" .Address .Port -}}
  {{- end -}}
{{- end -}}

{{- $server__http_listen_address := "0.0.0.0" -}}
{{- $server__http_listen_port := env "NOMAD_PORT_http" -}}
{{- $server__grpc_listen_address := "0.0.0.0" -}}
{{- $server__grpc_listen_port := env "NOMAD_PORT_grpc" -}}
{{- $memberlist__bind_addr := "[ 0.0.0.0 ]" -}}
{{- $memberlist__bind_port := env "NOMAD_PORT_gossip" }}

{{- $common__compactor_address := printf "%s%s" "http://" $backendHttpAddress -}}
{{- $common__compactor_grpc_address := $backendGrpcAddress -}}

{{- $TODO := "" -}}


{{- /* ------------------- */ -}}
{{- /*  Memberlist Config  */ -}}
{{- /* ------------------- */ -}}

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

{{- /* LOKI_READ */ -}}
{{ $read := sprig_dict -}}
{{- $_ := sprig_set $read "serviceName" $LOKI_READ -}}
{{- $_ := sprig_set $read "tag" "gossip" -}}
{{- $_ := sprig_set $read "indent" "4" -}}
{{- $_ := sprig_set $read "prefix" "- " -}}
{{- $_ := sprig_set $read "suffix" "" -}}

{{- /* LOKI_WRITE */ -}}
{{ $write := sprig_dict -}}
{{- $_ := sprig_set $write "serviceName" $LOKI_WRITE -}}
{{- $_ := sprig_set $write "tag" "gossip" -}}
{{- $_ := sprig_set $write "indent" "4" -}}
{{- $_ := sprig_set $write "prefix" "- " -}}
{{- $_ := sprig_set $write "suffix" "" -}}

{{- /* LOKI_BACKEND */ -}}
{{ $backend := sprig_dict -}}
{{- $_ := sprig_set $backend "serviceName" $LOKI_BACKEND -}}
{{- $_ := sprig_set $backend "tag" "gossip" -}}
{{- $_ := sprig_set $backend "indent" "4" -}}
{{- $_ := sprig_set $backend "prefix" "- " -}}
{{- $_ := sprig_set $backend "suffix" "" -}}

target: "all"
auth_enabled: false
ballast_bytes: 0
shutdown_delay: 0s

# how config are changed at runtime
runtime_config:
  period: 10s
  # TODO
  file: "" # comma-separated list of yaml files that can be updated at runtime

# This section does not work the way you think it does
# Docs does not mention what these parameter overrides
common:
  # instance_addr: 127.0.0.1
  compactor_address: {{ $common__compactor_address }}
  compactor_grpc_address: {{ $common__compactor_grpc_address }}
  # path_prefix: /var/nfs/nomad/loki
  # storage:
  #   filesystem:
  #     chunks_directory: /var/nfs/nomad/loki/data/shared/chunks
  #     rules_directory: /var/nfs/nomad/loki/data/shared/rules
#   replication_factor: 1
  ring:
    kvstore:
      store: memberlist
    instance_addr: {{ env "NOAMD_IP_gossip" }}
    instance_port: {{ env "NOMAD_PORT_gossip" }}


server:
  register_instrumentation: true
  graceful_shutdown_timeout: 30s
  http_path_prefix: "" # Base path to serve all API routes from (e.g. /v1/)
  
  # HTTP section
  http_listen_network: "tcp"
  http_listen_address: {{ $server__http_listen_address }}
  http_listen_port: {{ $server__http_listen_port }}
  http_listen_conn_limit: 0

  http_server_read_timeout: 30s
  http_server_write_timeout: 30s
  http_server_idle_timeout: 2m

  # GRPC section
  grpc_listen_network: "tcp"
  grpc_listen_address: {{ $server__grpc_listen_address }}
  grpc_listen_port: {{ $server__grpc_listen_port }}
  grpc_listen_conn_limit: 0

  grpc_server_max_recv_msg_size: 4194304
  grpc_server_max_send_msg_size: 4194304
  grpc_server_max_concurrent_streams: 100
  grpc_server_max_connection_idle: 2562047h47m16.854775807s
  grpc_server_max_connection_age: 2562047h47m16.854775807s
  grpc_server_max_connection_age_grace: 2562047h47m16.854775807s
  grpc_server_keepalive_time: 2h
  grpc_server_keepalive_timeout: 20s
  grpc_server_min_time_between_pings: 10s
  grpc_server_ping_without_stream_allowed: true

  # TLS section
  tls_cipher_suites: "" # Default Go cipher
  tls_min_version: "" # Default GO TLS min version, accepts VersionTLS10, VersionTLS11, VersionTLS12, VersionTLS13

  http_tls_config:
    cert_file: ""
    key_file: ""
    client_auth_type: ""
    client_ca_file: ""
  
  grpc_tls_config:
    cert_file: ""
    key_file: ""
    client_auth_type: ""
    client_ca_file: ""

  # Logging section
  log_format: "logfmt" # "logfmt", "json"
  log_level: "info"
  log_source_ips_enabled: false
  log_source_ips_header: ""
  log_request_headers: false
  log_request_at_info_level_enabled: false
  log_request_exclude_headers_list: ""

schema_config:
  configs:
    - from: 2024-01-31
      store: tsdb
      object_store: filesystem
      schema: v12
      index:
        prefix: index_
        period: 24h
        # tags: # map of strings to strings
      chunks:
        prefix:
        period:
        # tags: # map of strings to strings

storage_config:
  filesystem:
    directory: {{ $storage_config__filesystem__directory }}
  
  index_cache_validity: 5m
  # index_queries_cache_config: # no cache used, refer to cache_config block in docs
  disable_broad_index_queries: false
  max_parallel_get_chunk: 150
  max_chunk_batch_size: 50

  hedging: 
    at: 0s
    up_to: 2
    max_per_second: 5
  
  tsdb_shipper:
    active_index_directory: {{ $storage_config__tsdb_shipper__active_index_directory }}
    shared_store: filesystem
    shared_store_key_prefix: "index/"
    cache_location: {{ $storage_config__boltdb_shipper__cache_location }}
    cache_ttl: 24h
    resync_interval: 5m 
    query_ready_num_days: 0
    use_boltdb_shipper_as_backup: false
    ingestername: ""
    mode: ""
    # ingesterdbretainperiod: 
    enable_postings_cache: false

    index_gateway_client:
      server_address: "" # address of Index Gateway
      log_gateway_requests: false

      grpc_client_config:
        max_recv_msg_size: 104857600 # 100MB
        max_send_msg_size: 104857600 # 100MB
        grpc_compression: "" # "", "gzip", "snappy"
        rate_limit: 0
        rate_limit_burst: 0
        backoff_on_ratelimits: false

        backoff_config:
          min_period: 100ms
          max_period: 10s
          max_retries: 10
        
        initial_stream_window_size: 63KiB1023B
        initial_connection_window_size: 63KiB1023B
        tls_enabled: false
        tls_cert_path: ""
        tls_key_path: ""
        tls_ca_path: ""
        tls_server_name: ""
        tls_insecure_skip_verify: false
        tls_cipher_suites: ""
        tls_min_version: ""
        connect_timeout: 5s
        connect_backoff_base_delay: 1s
        connect_backoff_max_delay: 5s

chunk_store_config:
  # chunk_cache_config: # no cache
  # write_dedupe_cache_config:  # no cache
  cache_lookups_older_than: 0s
  max_look_back_period: 0s
  
memberlist:
  node_name: "" # Defaults to hostname
  randomize_node_name: true # makes node_name unique by concating random string to end
  stream_timeout: 10s
  retransmit_factor: 4
  pull_push_interval: 30s
  gossip_interval: 200ms
  gossip_nodes: 3 # TODO
  gossip_to_dead_nodes_time: 30s
  dead_node_reclaim_time: 0s
  compression_enabled: true
  advertise_addr: {{ env "NOMAD_IP_gossip" }}
  advertise_port: {{ env "NOMAD_PORT_gossip" }}
  cluster_label: ""
  cluster_label_verification_disabled: false
  join_members:  # TODO, list of strings, host:port
{{ template "printAddress" $read }}
{{- template "printAddress" $write }}
{{- template "printAddress" $backend }}
  min_join_backoff: 1s
  max_join_backoff: 1m
  max_join_retries: 10
  abort_if_cluster_join_fails: false
  rejoin_interval: 0s
  left_ingesters_timeout: 5m
  leave_timeout: 20s
  message_history_buffer_bytes: 0
  bind_addr: {{ $memberlist__bind_addr }}
  bind_port: {{ $memberlist__bind_port }}
  packet_dial_timeout: 2s
  packet_write_timeout: 5s
  tls_enabled: false
  tls_cert_path: ""
  tls_key_path: ""
  tls_ca_path: ""
  tls_server_name: ""
  tls_insecure_skip_verify: false
  tls_cipher_suites: ""
  tls_min_version: ""


# limits_config:
  # split_queries_by_interval: 1h

# table_manager:

# analytics:

# tracing:





# ==============================
#    Write Path
# ==============================

# Handles incoming streams from client
# First stop for write path
# Does validation, data normalization, 
# rate limiting, forwards data to [ingesters]
distributor:
  ring:
    kvstore:
      store: "memberlist"
      prefix: "collectors/"
    heartbeat_period: 5s
    heartbeat_timeout: 1m
      # instance_interface_names: []
  
  rate_store:
    max_request_parallelism: 200
    stream_rate_update_interval: 1s
    ingester_request_timeout: 500ms
    debug: false
  
  write_failures_logging:
    rate: 1000
    add_insights_label: false

# Write logs to store
# The ingester block configures the ingester and how the ingester will register
# itself to a key value store
ingester:
  lifecycler:
    ring:
      kvstore:
        store: "memberlist"
        prefix: "collectors/"
      heartbeat_timeout: 1m
      replication_factor: 1  # TODO
      zone_awareness_enabled: false
      excluded_zones: ""
    
    num_tokens: 128
    heartbeat_period: 5s
    heartbeat_timeout: 1m
    observe_period: 5s # default 4s
    join_after: 10s # default 0s
    min_ready_duration: 15s
    # interface_names: []
    enable_inet6: false
    final_sleep: 0s
    tokens_file_path: ""
    availability_zone: ""
    unregister_on_shutdown: true
    readiness_check_ring_health: true
    address: "" # TODO
    port: 0 # TODO
    id: "" # TODO, Defaults to hostname

  max_transfer_retries: 0
  concurrent_flushes: 32
  flush_check_period: 30s
  flush_op_timeout: 10m
  chunk_retain_period: 0s
  chunk_idle_period: 30m
  chunk_block_size: 262144
  chunk_target_size: 1572864
  chunk_encoding: "gzip" # "none", "gzip", "lz4-64k", "snappy", "lz4-256k", "lz4-1M", "lz4", "flate", "zstd"
  max_chunk_age: 30m # default 2h
  autoforget_unhealthy: false
  sync_period: 0s
  sync_min_utilization: 0
  max_returned_stream_errors: 10
  query_store_max_look_back_period: 0s

  wal:
    enabled: true
    dir: {{ $ingester__wal__dir }}
    checkpoint_duration: 5m
    flush_on_shutdown: false
    replay_memory_ceiling: 4GB
  
  index_shards: 32
  max_dropped_streams: 10
  shutdown_marker_path: {{ $ingester__wal__shutdown_marker_path }}

  # instance_interface_names: []


# The ingester_client block configures how the distributor will connect to
# ingesters. Only appropriate when running all components, the distributor, or
# the querier.
ingester_client:

  pool_config:
    client_cleanup_period: 15s
    health_check_ingesters: true
    remote_timeout: 1s
  
  remote_timeout: 5s
  
  grpc_client_config:
    max_recv_msg_size: 104857600 # 100MB
    max_send_msg_size: 104857600 # 100MB
    grpc_compression: "" # "", "gzip", "snappy"
    rate_limit: 0
    rate_limit_burst: 0
    backoff_on_ratelimits: false

    backoff_config:
      min_period: 100ms
      max_period: 10s
      max_retries: 10
    
    initial_stream_window_size: 63KiB1023B
    initial_connection_window_size: 63KiB1023B
    tls_enabled: false
    tls_cert_path: ""
    tls_key_path: ""
    tls_ca_path: ""
    tls_server_name: ""
    tls_insecure_skip_verify: false
    tls_cipher_suites: ""
    tls_min_version: ""
    connect_timeout: 5s
    connect_backoff_base_delay: 1s
    connect_backoff_max_delay: 5s


# ==============================
#    Read Path
# ==============================

# proxy for queriers
# splits queries, schedules them, and aggregates results (parallelism)
# retries, caches, manages rate limits
frontend:
  log_queries_longer_than: 0
  max_body_size: 10485760
  query_stats_enabled: false
  max_outstanding_per_tenant: 2048
  querier_forget_delay: 0s
  scheduler_address: "" # TODO
  scheduler_dns_lookup_period: 10s
  scheduler_worker_concurrency: 5 # TODO
  graceful_shutdown_timeout: 5m
  # instance_interface_names: []
  compress_responses: false
  downstream_url: "" # TODO
  tail_proxy_url: "" # TODO

  tail_tls_config: 
    tls_cert_path: ""
    tls_key_path: ""
    tls_ca_path: ""
    tls_server_name: ""
    tls_insecure_skip_verify: false
    tls_cipher_suites: ""
    tls_min_version: ""
    
  grpc_client_config:
    max_recv_msg_size: 104857600 # 100MB
    max_send_msg_size: 104857600 # 100MB
    grpc_compression: "" # "", "gzip", "snappy"
    rate_limit: 0
    rate_limit_burst: 0
    backoff_on_ratelimits: false

    backoff_config:
      min_period: 100ms
      max_period: 10s
      max_retries: 10
    
    initial_stream_window_size: 63KiB1023B
    initial_connection_window_size: 63KiB1023B
    tls_enabled: false
    tls_cert_path: ""
    tls_key_path: ""
    tls_ca_path: ""
    tls_server_name: ""
    tls_insecure_skip_verify: false
    tls_cipher_suites: ""
    tls_min_version: ""
    connect_timeout: 5s
    connect_backoff_base_delay: 1s
    connect_backoff_max_delay: 5s

# configures splitting and cacheing for frontend
query_range:
  align_queries_with_step: false
  results_cache:
    compression: "" # "", "gzip", "snappy"
    cache: 
      enable_fifocache: false
      default_validity: 1h0m0s
      background:
        writeback_goroutines: 10
        writeback_buffer: 10000
        writeback_size_limit: 1GB
      embedded_cache:
        enabled: true
        max_size_mb: 100
        ttl: 1h0m0s

  cache_results: false
  max_retries: 5
  parallelise_shardable_queries: true
  required_query_response_format: "json" # "json", "protobuf"
  cache_index_stats_results: false
  index_stats_results_cache:
    cache: 
      enable_fifocache: false
      default_validity: 1h0m0s
      background:
        writeback_goroutines: 10
        writeback_buffer: 10000
        writeback_size_limit: 1GB
      embedded_cache:
        enabled: true
        max_size_mb: 100
        ttl: 1h0m0s

    compression: ""

querier:
  tail_max_duration: 1h
  extra_query_delay: 0s
  query_ingesters_within: 3h
  engine:
    max_look_back_period: 30s
  max_concurrent: 16
  query_store_only: false
  query_ingester_only: false
  multi_tenant_queries_enabled: false
  per_request_limits_enabled: false

# The frontend_worker configures the worker - running within the Loki querier -
# picking up and executing queries enqueued by the query-frontend.
frontend_worker:
  frontend_address: "" # TODO: empty
  scheduler_address: "" # TODO: Backend hostname:port
  dns_lookup_duration: 3s
  parallelism: 10
  match_max_concurrent: true
  id: ""
  grpc_client_config:
    max_recv_msg_size: 104857600 # 100MB
    max_send_msg_size: 104857600 # 100MB
    grpc_compression: "" # "", "gzip", "snappy"
    rate_limit: 0
    rate_limit_burst: 0
    backoff_on_ratelimits: false

    backoff_config:
      min_period: 100ms
      max_period: 10s
      max_retries: 10
    
    initial_stream_window_size: 63KiB1023B
    initial_connection_window_size: 63KiB1023B
    tls_enabled: false
    tls_cert_path: ""
    tls_key_path: ""
    tls_ca_path: ""
    tls_server_name: ""
    tls_insecure_skip_verify: false
    tls_cipher_suites: ""
    tls_min_version: ""
    connect_timeout: 5s
    connect_backoff_base_delay: 1s
    connect_backoff_max_delay: 5s

# ==============================
#    Backend
# ==============================

ruler:
  # external_url: <url>
  datasource_uid: ""
  # external_labels: []
  evaluation_interval: 1m
  poll_interval: 1m

  ruler_client:
    max_recv_msg_size: 104857600 # 100MB
    max_send_msg_size: 104857600 # 100MB
    grpc_compression: "" # "", "gzip", "snappy"
    rate_limit: 0
    rate_limit_burst: 0
    backoff_on_ratelimits: false

    backoff_config:
      min_period: 100ms
      max_period: 10s
      max_retries: 10
    
    initial_stream_window_size: 63KiB1023B
    initial_connection_window_size: 63KiB1023B
    tls_enabled: false
    tls_cert_path: ""
    tls_key_path: ""
    tls_ca_path: ""
    tls_server_name: ""
    tls_insecure_skip_verify: false
    tls_cipher_suites: ""
    tls_min_version: ""
    connect_timeout: 5s
    connect_backoff_base_delay: 1s
    connect_backoff_max_delay: 5s

  storage:
    type: "local"
    local:
      directory: {{ $ruler__storage__local__directory }}
  rule_path: {{ $ruler__rule_path }}
  alertmanager_url: ""
  enable_alertmanager_discovery: false
  alertmanager_refresh_interval: 1m
  enable_alertmanager_v2: false
  # alert_relabel_configs: 
  notification_queue_capacity: 10000
  notification_timeout: 10s

  alertmanager_client:
    tls_cert_path: ""
    tls_key_path: ""
    tls_ca_path: ""
    tls_server_name: ""
    tls_insecure_skip_verify: false
    tls_cipher_suites: ""
    tls_min_version: ""
    basic_auth_username: ""
    basic_auth_password: ""
    type: "Bearer" # HTTP Header authorization type
    credentials: ""
    credentials_file: ""
  
  for_outage_tolerance: 1h
  for_grace_period: 10m
  resend_delay: 1m
  enable_sharding: false
  sharding_strategy: "default" # "default", "shuffle-sharding"
  sharding_algo: "by-group" # "by-group", "by-rule"
  search_pending_for: 5m

  ring:
    kvstore:
      store: "memberlist"
      prefix: "collectors/"
    heartbeat_period: 5s
    heartbeat_timeout: 1m
    # instance_interface_names: []
    num_tokens: 128
    
  flush_period: 1m
  enable_api: true
  enabled_tenants: ""
  disabled_tenants: ""
  query_stats_enabled: false
  disable_rule_group_label: false

  wal:
    dir: {{ $ruler__wal__dir }}
    truncate_frequency: 1h
    min_age: 5m
    max_age: 4h

  wal_cleaner:
    min_age: 12h
    period: 0s

  remote_write:
    # client:
    # clients:
    enabled: false
  
  evaluation:
    mode: "local" # "local", "remote"
    max_jitter: 0

    query_frontend:
      address: # TODO
      tls_enabled: false
      tls_cert_path: ""
      tls_key_path: ""
      tls_ca_path: ""
      tls_server_name: ""
      tls_insecure_skip_verify: false
      tls_cipher_suites: ""
      tls_min_version: ""

# serves index queries without needing to
# repeatedly interact with object store
index_gateway:
  mode: "simple" # "simple", "ring"
  ring:
    kvstore:
      store: "memberlist" # "consul", "etcd", "inmemory", "memberlsit", "multi"
      prefix: "collectors/"
    heartbeat_period: 15s
    heartbeat_timeout: 1m
    tokens_file_path: ""
    zone_awareness_enabled: false
    # instance_id: 
    # instance_interface_names: []
    # instance_port: 0 # TODO
    # instance_addr: 127.0.0.1 # TODO
    instance_availability_zone: ""
    instance_enable_ipv6: false
    replication_factor: 1 # TODO

compactor:
  working_directory: {{ $compactor__working_directory }}
  shared_store: "filesystem"
  shared_store_key_prefix: "index/"
  compaction_interval: 10m
  apply_retention_interval: 0s
  retention_enabled: false
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
  retention_table_timeout: 0s
  delete_request_store: ""
  delete_batch_size: 70
  delete_request_cancel_period: 24h
  delete_max_interval: 0s
  max_compaction_parallelism: 1
  upload_parallelism: 10
  tables_to_compact: 0
  skip_latest_n_tables: 0

  compactor_ring:
    kvstore:
      store: "memberlist"
      prefix: "collectors/"
      
    heartbeat_period: 15s
    heartbeat_timeout: 1m
    tokens_file_path: ""
    zone_awareness_enabled: false
    # instance_id: "" default = "<hostname>"
    # instance_interface_names: []
    # instance_port: 0 # TODO
    # instance_addr: 127.0.0.1 # TODO
    instance_availability_zone: ""
    instance_enable_ipv6: false

# Queue for frontend that runs on a separate process
# to allow for multiple frontends
query_scheduler:
  max_outstanding_requests_per_tenant: 32768
  max_queue_hierarchy_levels: 3
  querier_forget_delay: 0
  
  grpc_client_config:
    max_recv_msg_size: 104857600 # 100MB
    max_send_msg_size: 104857600 # 100MB
    grpc_compression: "" # "", "gzip", "snappy"
    rate_limit: 0
    rate_limit_burst: 0
    backoff_on_ratelimits: false

    backoff_config:
      min_period: 100ms
      max_period: 10s
      max_retries: 10
    
    initial_stream_window_size: 63KiB1023B
    initial_connection_window_size: 63KiB1023B
    tls_enabled: false
    tls_cert_path: ""
    tls_key_path: ""
    tls_ca_path: ""
    tls_server_name: ""
    tls_insecure_skip_verify: false
    tls_cipher_suites: ""
    tls_min_version: ""
    connect_timeout: 5s
    connect_backoff_base_delay: 1s
    connect_backoff_max_delay: 5s
  
  use_scheduler_ring: false # TODO
  scheduler_ring:
    kvstore: 
      store: "memberlist"
      prefix: "collectors/"
    heartbeat_period: 15s
    heartbeat_timeout: 1m
    tokens_file_path: ""
    zone_awareness_enabled: false
    # instance_id: # defaults to hostname
    # instance_interface_names: []
    # instance_port: 0 # TODO
    # instance_addr: 127.0.0.1 # TODO
    instance_availability_zone: ""
    instance_enable_ipv6: false

