
<!-- vim-markdown-toc GFM -->

* [Running locally](#running-locally)
    * [Testing](#testing)
* [Cleaning](#cleaning)

<!-- vim-markdown-toc -->

# Running locally

- To run the application locally we can simply execute:

```bash
make up
```

(Use `make upd` if you don't want your terminal to be stuck on the container's output.)

- Wait a while for the services to start. After they are up and running check that we are accepting connections:

```bash
curl --head http://localhost:5000/
```

## Testing

- To run a simple validation that we can use the service and upload files as expected:

```bash
make local_test
```

This will output an URL that can be accessed locally with the file that was uploaded on the test.

(The tests are being executed by the `scripts/simple_validation.sh` script)

- To manually test the file upload process, execute

```bash
curl -F "file_to_upload=@path_to_a_file" http://localhost:5000/upload/
```

**NOTE:** All the steps mentioned above, from initialization to testing, can be automatically executed by simply running `make`

**NOTE2:** If you simply execute `make`, there is a chance that everything runs so fast that the required services will not be available yet. To fix it simply run `make` again. An example of this error is this:

```
An error occurred (502) when calling the CreateBucket operation (reached max retries: 4): Bad Gateway
Makefile:54: recipe for target 'local_test' failed
make: *** [local_test] Error 255
```

# Cleaning

To clean everything (including images and volumes), after you are done testing and developing, use:

```bash
make fresh
```
