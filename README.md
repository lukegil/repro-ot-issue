
This repo is a minimal repro of an issue where the otel collector returns a 400 for traced faraday requests.

## Setting up

1. Start running the otel collector by running `docker-compose up`
2. Start running the app
```
cd rails-app
rvm use 3.0.6
bundle install
OTEL_TRACES_EXPORTER=zipkin bundle exec rails server -p 8080
```
3. Call the endpoint

```
curl --location 'http://127.0.0.1:8080/get200'
```

## Observed behavior

The exporter errors with something like 
```
E, [2024-04-30T17:41:10.856637 #81596] ERROR -- : OpenTelemetry error: Unable to export 4 spans
```

To actually observe the error from the otel-collector you'll have to add some prints to the zipkin exporter. 
```
# vendor/bundle/ruby/3.0.0/gems/opentelemetry-exporter-zipkin-0.23.1/lib/opentelemetry/exporter/zipkin/exporter.rb

def send_spans(zipkin_spans, timeout: nil) # rubocop:disable Metrics/MethodLength
          retry_count = 0
          timeout ||= @timeout
          start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
          around_request do # rubocop:disable Metrics/BlockLength
          
          ...

            puts "response: #{response}"
            puts "response.code: #{response.code}"
            puts "response.body: #{response.body}"
            puts "request: #{request.body}"

            case response
            when Net::HTTPAccepted, Net::HTTPOK

```

The server returns a 400 with the error
```
json: cannot unmarshal string into Go struct field Endpoint.remoteEndpoint.Port of type uint16
```

The request is something like...

```
[
  {
    "name": "connect",
    "traceId": "d7101b3e1b434b9de5901c2a2560e6d7",
    "id": "eaf7ebaf7bf997b8",
    "timestamp": 1714512950551390,
    "duration": 177952,
    "debug": false,
    "tags": {
      "otel.scope.name": "OpenTelemetry::Instrumentation::Net::HTTP",
      "otel.library.name": "OpenTelemetry::Instrumentation::Net::HTTP",
      "otel.scope.version": "0.22.4",
      "otel.library.version": "0.22.4",
      "net.peer.name": "httpstat.us",
      "net.peer.port": "443"
    },
    "kind": null,
    "parentId": "18e045762b7b0f1b",
    "localEndpoint": { "serviceName": "dice-ruby" },
    "remoteEndpoint": { "port": "443" }
  },
  {
    "name": "HTTP GET",
    "traceId": "d7101b3e1b434b9de5901c2a2560e6d7",
    "id": "ed357a6099f83b2a",
    "timestamp": 1714512950729589,
    "duration": 62022,
    "debug": false,
    "tags": {
      "otel.scope.name": "OpenTelemetry::Instrumentation::Net::HTTP",
      "otel.library.name": "OpenTelemetry::Instrumentation::Net::HTTP",
      "otel.scope.version": "0.22.4",
      "otel.library.version": "0.22.4",
      "http.method": "GET",
      "http.scheme": "https",
      "http.target": "/200",
      "net.peer.name": "httpstat.us",
      "net.peer.port": "443",
      "http.status_code": "200"
    },
    "kind": "CLIENT",
    "parentId": "18e045762b7b0f1b",
    "localEndpoint": { "serviceName": "dice-ruby" },
    "remoteEndpoint": { "port": "443" }
  },
  {
    "name": "HTTP GET",
    "traceId": "d7101b3e1b434b9de5901c2a2560e6d7",
    "id": "18e045762b7b0f1b",
    "timestamp": 1714512950541606,
    "duration": 250180,
    "debug": false,
    "tags": {
      "otel.scope.name": "OpenTelemetry::Instrumentation::Faraday",
      "otel.library.name": "OpenTelemetry::Instrumentation::Faraday",
      "otel.scope.version": "0.23.4",
      "otel.library.version": "0.23.4",
      "http.method": "GET",
      "http.url": "https://httpstat.us/200",
      "net.peer.name": "httpstat.us",
      "http.status_code": "200"
    },
    "kind": "CLIENT",
    "parentId": "918360ba5a7bfdff",
    "localEndpoint": { "serviceName": "dice-ruby" },
    "remoteEndpoint": {}
  },
  {
    "name": "TwoHundredController#get",
    "traceId": "d7101b3e1b434b9de5901c2a2560e6d7",
    "id": "918360ba5a7bfdff",
    "timestamp": 1714512950401955,
    "duration": 390847,
    "debug": false,
    "tags": {
      "otel.scope.name": "OpenTelemetry::Instrumentation::Rack",
      "otel.library.name": "OpenTelemetry::Instrumentation::Rack",
      "otel.scope.version": "0.23.5",
      "otel.library.version": "0.23.5",
      "http.method": "GET",
      "http.host": "127.0.0.1:8080",
      "http.scheme": "http",
      "http.target": "/get200",
      "http.user_agent": "PostmanRuntime/7.37.3",
      "code.namespace": "TwoHundredController",
      "code.function": "get",
      "http.status_code": "200"
    },
    "kind": "SERVER",
    "localEndpoint": { "serviceName": "dice-ruby" },
    "remoteEndpoint": {}
  }
]
```
