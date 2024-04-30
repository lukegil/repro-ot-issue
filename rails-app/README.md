# Running this app

```
rvm use 3.0.6
bundle install
OTEL_TRACES_EXPORTER=zipkin bundle exec rails server -p 8080
```
