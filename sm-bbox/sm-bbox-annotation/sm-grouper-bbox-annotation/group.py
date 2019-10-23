#!/usr/bin/env python3

# Author: Verdi March

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


class Grouper(object):
    DEFAULT = {
        'ann_input_dir': './train_annotation',
        'img_input_dir': './train',
        'ann_output_s3': None,
        'img_output_s3': None,
        'group_size': 6,
        'count': 50,
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


    def generate(self):
        '''Generate new images from pieces.'''
        self._file_id = 0
        self._fs = s3fs.S3FileSystem(anon=False, profile_name=self.aws_profile)

        for i in range(self.count):
            merged_ann, merged_img = self.generate_new_data()

            # Upload new assets to S3
            self.upload_img(merged_img, merged_ann['file'])
            self.upload_ann(merged_ann)

            self._file_id += 1


    def generate_new_data(self) -> Tuple[Annotation_t, Image_t]:
        '''Generate a new image from pieces.'''

        # Random samples of pieces out of all input annotations.
        pieces: List[str] = random.sample(self.ann_input_fnames, k=self.group_size)
        logger.info(f'Merge pieces: {pieces}')

        # Load JSON annotation and image of pieces from local filesystem.
        anns: List[Annotation_t] = [json.load(open(fname)) for fname in pieces]
        # Fix for JSON annotation with missing categories
        for d in anns:
            d['categories'] = d.get('categories', [])
        images: List[Image_t] = self.load_images(anns)

        # Compute target height & width (we assume image pieces can vary in height or width)
        pieces_h, pieces_w = zip(*[x.shape[:2] for x in images])
        logger.debug(f'Pieces heights x widths: {pieces_h} x {pieces_w}')

        # Compute width, height of grouped image
        h, w = sum(pieces_h), max(pieces_w)
        logger.debug(f'Size of new image: {(h,w)}')

        # Get y offset of each piece in new image
        y_offsets = self.get_y_offsets(pieces_h)
        logger.debug(f'y offsets: {y_offsets}')

        # Merge image pieces into a single new image
        merged_img: Image_t = self.merge_image(images, h, w, y_offsets)

        # Recompute bboxes
        anns2: List[Annotation_t] = self.adjust_bbox(anns, y_offsets)

        # Construct new annotation for the merged image
        merged_ann: Annotation_t = self.merge_anns(anns2, w, h, 3)

        return merged_ann, merged_img


    def upload_img(self, img: Image_t, fname: str):
        '''Save an image to S3.'''
        s3_key = f'{self.img_output_s3}/{fname}'
        with self._fs.open(s3_key, 'wb') as f:
            content = cv2.imencode('.jpg', img)[1].tostring()
            f.write(content)
        logger.info(f'Uploaded image: {s3_key}')


    def upload_ann(self, ann: Annotation_t):
        '''Save a dictionary as JSON file to S3.'''
        s3_key = f'{self.ann_output_s3}/image-{self._file_id:07d}.json'
        with self._fs.open(s3_key, 'wb') as f:
            content = json.dumps(ann).encode(encoding='utf-8', errors='strict')
            f.write(content)
        logger.info(f'Uploaded annotation: {s3_key}')


    def load_images(self, anns: List[Annotation_t]) -> List[Image_t]:
        '''Load 3-channel image pieces from local filesystem. This method will
        map the S3 path of each image piece to local dir indicated in
        `image_input_dir`.

        :param anns: list of annotation pieces.
        '''
        local_img_fnames: List[Path] = [self.img_input_dir / d['file'] for d in anns]
        images: List[Image_t] = [cv2.imread(str(p), 1) for p in local_img_fnames]
        return images


    def get_y_offsets(self, pieces_h: 'np array-like') -> Image_t:
        '''Compute y-offset of each image pieace in the new image. This offset
        determines the vertical starting point of each image piece.
        
        +------------------+ => y = 0 
        | image-00         |
        +------------------+ => y = height of image-00
        | image-01         |
        +------------------+ => y = sum(heights of previous images)
        | ...              |
        +------------------+
        '''
        y_offsets = np.zeros(len(pieces_h), dtype=np.int64)
        y_offsets[1:] = np.cumsum(pieces_h[0:-1])
        return y_offsets


    def merge_image(self, images: List[Image_t], target_h: int, target_w: int, y_offsets) -> Image_t:
        '''Merge image pieces into a new target image.

        :returns: new image.
        '''
        # Allocate a black RGB image (i.e., all-zero array)
        merged_img: Image_t = np.zeros((target_h, target_w, 3), dtype=np.uint8)

        # Put image pieces one by one
        for img, offset in zip(images, y_offsets):
            height = img.shape[0]
            merged_img[offset:offset+height, :, :] = img

        return merged_img


    def adjust_bbox(self, anns: List[Annotation_t], y_offsets: Iterator[int]) -> List[Annotation_t]:
        '''Correct bboxes of pieces in the new image by adding the right amount
        of offset.

        :param anns: list of annotation pieces
        :param y_offsets: offset for each pieces
        '''
        ann2 = []
        for d, offset in zip(anns, y_offsets):
            d2 = copy.deepcopy(d)
            for bbox in d2['annotations']:
                # Need int() otherwise lhs is np.int64 which chokes json.dumps()
                bbox['top'] += int(offset)
            ann2.append(d2)
        return ann2


    def merge_anns(self, anns: List[Annotation_t], w: int, h: int, c: int) -> Annotation_t:
        '''Merge annotation pieces into a single annotation.

        :param anns: list of annotation pieces
        :return: a new annotation constructed from the pieces
        '''
        merged_fname = f'image-{self._file_id:07d}.jpg'
        logger.debug(f'merged_fname: {merged_fname}')

        # If categories collide, then the last seen category wins.
        new_cat: Dict[int, str] = {}
        for cat_d in chain(*(d['categories'] for d in anns)):
            new_cat[cat_d['class_id']] = cat_d['name']

        merged_ann = {
           "file": merged_fname,
           "image_size": [{
               'width': w,
               'height': h,
               'depth': c
           }],
           "annotations": [bbox for bbox in chain(*(d['annotations'] for d in anns))],
           #"categories": [{'class_id': k, 'name': v} for k,v in new_cat.items()]
           "categories": [ {'class_id': i, 'name': f'class_{i}'} for i in range(5)]
        }

        logger.debug(f'merged_ann: {merged_ann}')
        return merged_ann


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('ann_output_s3', metavar='ANN_OUTPUT_S3', help='S3 path of output annotation')
    parser.add_argument('img_output_s3', metavar='IMG_OUTPUT_S3', help='S3 path of output image')
    parser.add_argument('-i', '--ann-input-dir', help='Path to input annotation', default='./train_annotation')
    parser.add_argument('-g', '--img-input-dir', help='Path to input image', default='./train')
    parser.add_argument('-s', '--group-size', help='Number of original images per new image', default=6, type=int)
    parser.add_argument('-c', '--count', help='Number of images to generate', default=50, type=int)
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
    g = Grouper(**opts)
    g.generate()
