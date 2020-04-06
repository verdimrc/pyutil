## Conda

```bash
conda create --clone tensorflow_p36 --prefix ~/SageMaker/my_tensorflow
source activate ~/SageMaker/my_tensorflow
#https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#cloning-an-environment
```
 
## Docker

```bash
vim /etc/docker/daemon.json 
 
#Add the following
{
  "data-root": "~/SageMaker/docker"
}

sudo service docker stop
sudo service docker start
#https://docs.docker.com/engine/reference/commandline/dockerd/
```
 
## MATLAB dockerfile

https://github.com/mathworks-ref-arch/matlab-dockerfile

They also host a built container image at NVIDIA's repo: https://ngc.nvidia.com/catalog/containers/partners:matlab
Of course you'll need to bring your own license.
