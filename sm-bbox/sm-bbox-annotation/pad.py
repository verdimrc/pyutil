#!/usr/bin/env python3

# Author: Verdi March

'''Pad each image and update the image's annotation.'''

import argparse
import copy
import cv2
from itertools import chain
import json
import logging
import numpy as np
import os
from pathlib import Path
import random
import s3fs
from typing import Any, Dict, List, Iterator, Tuple

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Disable debug logging for imported modules
for i in ('s3fs', 'urllib3'):
    logging.getLogger(i).setLevel(logging.WARN)

# For Python type annotations
Annotation_t = Dict[Any, Any]
Image_t = np.ndarray


class Padder(object):
    DEFAULT = {
        'ann_input_dir': './train_annotation',
        'img_input_dir': './train',
        'ann_output_s3': None,
        'img_output_s3': None,
        'aws_profile': 'default',

    }

    def __init__(self, **kwargs):
        '''Create a new grouper to merge image and annotation pieces to a single
        image and a single annotation.

        Parameters: see Grouper.DEFAULT
        '''
        for k,v in kwargs.items():
            setattr(self, k,v)

        # Convert string to Path object
        self.ann_input_dir = Path(self.ann_input_dir)
        self.img_input_dir = Path(self.img_input_dir)

        # File names of all input annotations.
        self.ann_input_fnames: List[str] = [str(p) for p in Path(self.ann_input_dir).glob('**/*.json')]


    def pad_all(self):
        '''Generate new images from pieces.'''
        self._fs = s3fs.S3FileSystem(anon=False, profile_name=self.aws_profile)

        for ann_fname in self.ann_input_fnames:
            padded_ann, padded_img = self.pad(ann_fname)

            # Upload new assets to S3
            self.upload_img(padded_img, padded_ann['file'])
            self.upload_ann(padded_ann, ann_fname.rsplit('/', 1)[-1])


    def pad(self, ann_fname: str) -> Tuple[Annotation_t, Image_t]:
        '''Generate a padded image from a piece image.'''
        logger.info(f'Pad piece: {ann_fname}')

        # Load JSON annotation and image of piece from local filesystem.
        ann: Annotation_t = json.load(open(ann_fname))
        image: Image_t = self.load_image(ann)

        # Compute target height & width (we assume image pieces can vary in height or width)
        piece_h, piece_w = image.shape[:2]
        logger.debug(f'Piece height x width: {piece_h} x {piece_w}')

        # Compute width, height of padded image
        if piece_h < piece_w:
            h, w = piece_w, piece_w
        else:
            h, w = piece_h, piece_w
        logger.debug(f'Size of new image: {(h,w)}')

        # Pad the image piece into a new image
        padded_img: Image_t = self.pad_image(image, h, w)

        # Construct new annotation for the padded image
        padded_ann: Annotation_t = self.pad_ann(ann, w, h, 3)

        return padded_ann, padded_img


    def upload_img(self, img: Image_t, fname: str):
        '''Save an image to S3.'''
        s3_key = f'{self.img_output_s3}/{fname}'
        with self._fs.open(s3_key, 'wb') as f:
            content = cv2.imencode('.jpg', img)[1].tostring()
            f.write(content)
        logger.info(f'Uploaded image: {s3_key}')


    def upload_ann(self, ann: Annotation_t, ann_fname: str):
        '''Save a dictionary as JSON file to S3.'''
        s3_key = f'{self.ann_output_s3}/{ann_fname}'
        with self._fs.open(s3_key, 'wb') as f:
            content = json.dumps(ann).encode(encoding='utf-8', errors='strict')
            f.write(content)
        logger.info(f'Uploaded annotation: {s3_key}')


    def load_image(self, ann: Annotation_t) -> Image_t:
        '''Load a 3-channel image from local filesystem. This method will
        map the S3 path of each image piece to local dir indicated in
        `image_input_dir`.

        :param ann: piece annotation.
        '''
        local_img_fname: Path = self.img_input_dir / ann['file']
        image: Image_t = cv2.imread(str(local_img_fname), 1)
        return image


    def pad_image(self, image: Image_t, target_h: int, target_w: int) -> Image_t:
        '''Pad piece image into a new target image.

        :returns: new image.
        '''
        # Allocate a black RGB image (i.e., all-zero array)
        padded_img: Image_t = np.zeros((target_h, target_w, 3), dtype=np.uint8)

        # Put image pieces one by one
        height, width = image.shape[:2]
        padded_img[0:height, 0:width, :] = image

        return padded_img


    def pad_ann(self, ann: Annotation_t, w: int, h: int, c: int) -> Annotation_t:
        '''Merge annotation pieces into a single annotation.

        :param anns: list of annotation pieces
        :return: a new annotation constructed from the pieces
        '''
        padded_fname = ann['file'].rsplit('/', 1)[-1]
        logger.debug(f'padded_fname: {padded_fname}')

        padded_ann = copy.deepcopy(ann)
        padded_ann['file'] = padded_fname
        padded_ann['image_size'][0]['width'] = w
        padded_ann['image_size'][0]['height'] = h
        padded_ann['image_size'][0]['depth'] = c
        padded_ann['categories'] = [{'class_id': i, 'name': f'class_{i}'} for i in range(5)]

        logger.debug(f'padded_ann: {padded_ann}')
        return padded_ann


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('ann_output_s3', metavar='ANN_OUTPUT_S3', help='S3 path of output annotation')
    parser.add_argument('img_output_s3', metavar='IMG_OUTPUT_S3', help='S3 path of output image')
    parser.add_argument('-i', '--ann-input-dir', help='Path to input annotation', default='./train_annotation')
    parser.add_argument('-g', '--img-input-dir', help='Path to input image', default='./train')
    parser.add_argument('-p', '--aws-profile', help='AWS profile', default='default')
    parser.add_argument('-v', '--verbose', help='Verbose/debug mode', default=False, action='store_true')
    args = parser.parse_args()

    # Display selected configurations
    logger.info(f'Annotation input dir: {args.ann_input_dir}')
    logger.info(f'Image input dir: {args.img_input_dir}')
    logger.info(f'Annotation output S3: {args.ann_output_s3}')
    logger.info(f'Image output S3: {args.img_output_s3}')

    # Set verbosity of logs
    if args.verbose:
        logger.setLevel(logging.DEBUG)

    # Start grouping
    opts = vars(args)
    opts.pop('verbose')
    p = Padder(**opts)
    p.pad_all()
