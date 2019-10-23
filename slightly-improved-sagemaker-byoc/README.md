Two Dockerfile are provided: a CPU variant, and another GPU variant. The later
include CUDA configuration.

By default, both Dockerfiles uses containers in the SageMaker's ECR as their
base, and the `build_and_push.sh` script include authentication to SageMaker's
ECR. Note that SageMaker allows only open-sourced containers to be pulled, and
not the built-in / 1P / 1st-party algorithms.

To switch to DL container as the base, uncomment the relevant line (i.e., BASE)
in Dockerfiles, and also the authentication line in `build_and_push.sh`. See the
DeepLearning container documentation for more details.

To build GPU variant, you must invoke `./build_and_push.sh -g ...`.

Lastly, you can invoke symlinks `build.sh` and `push.sh` to just build and
push, respectively.
