There are a few options to build:

- run `./build.sh` on an EC2 instance running `alinux2` AMI
- build through CodeBuild using the `alinux2` container.

Note that CodeBuild build log will show error messages related to `awscli`, which are shown below. These error messages can be safely ignored as they do not affect the resulted layer.

```
...
Successfully built s3fs sklearn fsspec 
ERROR: aws-sam-cli 0.22.0 has requirement six~=1.11.0, but you'll have six 1.12.0 which is incompatible. 
ERROR: awscli 1.16.242 has requirement botocore==1.12.232, but you'll have botocore 1.13.2 which is incompatible. 
Installing collected packages: pytz, six, python-dateutil, numpy, pandas, xlrd, jmespath, urllib3, docutils, botocore, s3transfer, boto3, fsspec, s3fs, joblib, scipy, scikit-learn, sklearn 
Successfully installed boto3-1.10.2 botocore-1.13.2 docutils-0.15.2 fsspec-0.5.2 jmespath-0.9.4 joblib-0.14.0 numpy-1.17.3 pandas-0.25.2 python-dateutil-2.8.0 pytz-2019.3 s3fs-0.3.5 s3transfer-0.2.1 scikit-learn-0.21.3 scipy-1.3.1 six-1.12.0 sklearn-0.0 urllib3-1.25.6 xlrd-1.2.0
...
```
