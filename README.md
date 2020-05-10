Sinatra Graceful Shutdown
=========================

A sample server and testing utilities to demonstrate graceful shutdowns and zero-downtime deployments.

Quick Start
-----------

```sh
bundle                   # install dependencies
./test-single-server.rb  # run test against single server
```

Running the server manually
---------------------------

To see how the server behaves without any of the test scripts, you can run it manually:

```sh
bundle    # install dependencies
./app.rb  # run the server
```

Now, in a separate terminal, request an "echo". You'l get an answer after a short delay:

```
$ curl 'http://localhost:4567/wait-and-echo?content=content%20to%20echo'
ECHO: content to echo
```

Or, run the health check:

```
$ curl -i 'http://localhost:4567/health'
HTTP/1.1 204 No Content
<headers omitted>
```
