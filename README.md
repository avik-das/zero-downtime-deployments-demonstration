Sinatra Graceful Shutdown
=========================

A sample server and testing utilities to demonstrate graceful shutdowns and zero-downtime deployments.

Quick Start
-----------

```sh
bundle    # install dependencies
./app.rb  # run the server
```

```
$ # In a separate terminal, request an echo
$ # You'll get an answer after a short delay
$ curl 'http://localhost:4567/wait-and-echo?content=content%20to%20echo'
ECHO: content to echo
```
