#!/usr/bin/env python3

"""Split augmented manifest (i.e., Ground Truth's output) to train & validation channels."""

import argparse
import os
from random import shuffle
import s3fs
from typing import Any, List, Tuple


def split(annot: List[Any], train_ratio=0.8) -> Tuple[List[Any], List[Any]]:
    """Shuffle and split input list."""
    x = list(range(len(annot)))
    shuffle(x)
    cutoff = int(0.8 * len(x))
    x_train, x_valid = x[:cutoff], x[cutoff:]
    return select(annot, x_train), select(annot, x_valid)


def select(x: List[Any], idx: int) -> List[Any]:
    """Select elements in x at indices indicated in idx."""
    return [x[i] for i in idx]


def save_augmented_manifest_to_s3(fs, s3_path: str, x: List[str]):
    """Upload a new augmented manifest."""
    with fs.open(s3_path, 'w') as f:
        for line in x:
            f.write(line)

            
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input', metavar='INPUT', help='S3 keyname of input augmented manifest')
    parser.add_argument('train', metavar='TRAIN', help='S3 keyname of train channel')
    parser.add_argument('valid', metavar='VALID', help='S3 keyname of validation channel')
    parser.add_argument('-r', '--train-ratio', help='Ratio of train data (must be a number 0-1)', default=0.8, type=float)
    parser.add_argument('-p', '--profile', help='Profile name of AWS credential', default='default')
    args = parser.parse_args()

    fs = s3fs.S3FileSystem(anon=False, profile_name=args.profile)
    annots = []
    with fs.open(args.input, 'rb') as f:
        for line_bytes in f:
            annots.append(line_bytes.decode())

    if not (0.0 <= args.train_ratio <= 1.0):
        raise ValueError(f'Train ratio must be 0-1, but received {args.train_ratio}')

    x_train, x_valid = split(annots, args.train_ratio)
    save_augmented_manifest_to_s3(fs, args.train, x_train)
    save_augmented_manifest_to_s3(fs, args.valid, x_valid)
