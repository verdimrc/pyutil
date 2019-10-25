#!/usr/bin/env bash

# This script install packages to ./python
# NOTE: You could also choose to install to ./python/lib/python3.7/site-packages
#       See https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html#configuration-layers-path
#       (and see the Python section).
echo "Please ensure that you run me on alinux2"

# Install python-3.7
echo "installing python-3.7; need sudo"
if [[ $EUID -ne 0 ]]; then
    echo 'Script is NOT run as root'
    sudo yum install -y python3 python3-dev python3-pip
else
    echo 'Script is run as root'
    yum install -y python3 python3-dev python3-pip
fi

# Delete old installation directory if exists
rm -fr python; mkdir python/

# Pip install packages to ./python.
# NOTE:
# - --target python instructs pip to install packages to python subdir (in the current dir).
# - packages installed: pandas, xlrd, s3fs, and sklearn.
# - update s3fs in lambda to the latest version to allow pandas to do df.to_csv('s3://....').
# - xlrd to allow pandas to read_excel()
pip3 install --target python pandas xlrd s3fs sklearn

# Remove excess fat to ensure python/ stays at 250MB max. (i.e., 262144000 bytes).
cd python/
find . -name '*.so' | xargs -n1 strip --strip-unneeded
find scipy -type d -name tests | xargs rm -fr
find sklearn -type d -name tests | xargs rm -fr
cd ..

# Confirm the final uncompressed size
du -shc python/

# Compress packages
zip -9qr pd-xlrd-sklearn-s3fs-3.7.zip python/

# Final reminder to upload the zip file to S3.
echo "Final reminder: upload pd-xlrd-sklearn-s3fs-3.7.zip to S3"
echo "After the zipped layer lands in S3, go to the Lambda console and create your layer."
