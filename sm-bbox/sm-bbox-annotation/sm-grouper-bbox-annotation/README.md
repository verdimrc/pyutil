# Prepare Test Data (if needed)

Modify paths in `01-annotate-img.sh` and `02-upload-test-data.sh` as necessary.

```bash
# Generate annotation for each test image.
./01-annotate-img.sh

# Upload test images & annotations to S3.
./02-upload-test.data.sh
```

# Steps to Merge

First, you need to download the input pieces (i.e., JSON annotations and images)
from S3 to local directories. The reason for this is because the same piece can
be used for many target images, hence it makes sense to avoid multiple
round-trip to re-download the image+annotation of the same piece.

Afterwards, you can run `group.py`.

```bash
# Download the images and annotations of input pieces to local dir.
$ aws --profile=default s3 sync s3://bucket/grouper/train/ train/
$ aws --profile=default s3 sync s3://bucket/grouper/train_annotation/ train_annotation/

# Start grouping: generate 2 images, each of which consists of 6 pieces randomly chosen
# from the set of all image pieces.
$ ./group.py --aws-profile fuxin \
    --count 2 \
    --group-size 6 \
    --ann-input-dir ./train_annotation \
    --img-input-dir ./train \
    s3://bucket/grouper/traing_annotation \
    s3://bucket/grouper/traing
```

# How it works

Refer to `../sm-bbox-annotation-merge.ipynb`.
