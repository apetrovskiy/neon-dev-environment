# Tracer-API testing environment

## Building images
```sh
./build.sh
```

## Running tests
```sh
./run.sh <run_name>
```

directory named **./test-logs/<run_name>/** will be created
Logs will be saved to files:
- neon-tracer.log
- neon-tracer-test.log
- proxy.log
- validator.log
- tracer_db.log

