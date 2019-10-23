#!/usr/bin/env python3

# Author: Verdi March

"""Usage: ./sm-draw-bbox-annotation.py --ann-input-dir $IMG_ROOT/annotations --img-input-dir $IMG_ROOT/images $IMG_ROOT/bboxed_images"""

import argparse
import cv2
import json
import logging
import numpy as np
import os
from pathlib import Path
from typing import Any, Dict, List, Tuple

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# For Python type annotations
Annotation_t = Dict[Any, Any]
Image_t = np.ndarray


class Bboxer(object):
    DEFAULT = {
        'ann_input_dir': './train_annotation',
        'img_input_dir': './train',
        'img_output_dir': None,
    }

    def __init__(self, **kwargs):
        '''Create a new bboxer to draw bboxes from annotations to their
        corresponding images.

        Parameters: see Bboxer.DEFAULT
        '''
        for k,v in kwargs.items():
            setattr(self, k,v)

        # Convert string to Path object
        self.ann_input_dir = Path(self.ann_input_dir)
        self.img_input_dir = Path(self.img_input_dir)

        # File names of all input annotations.
        self.ann_input_fnames: List[str] = [str(p) for p in Path(self.ann_input_dir).glob('**/*.json')]


    def apply_all(self):
        '''Draw bboxes on all images.'''

        for ann_fname in self.ann_input_fnames:
            bboxed_img, obasename = self.apply(ann_fname)

            # Save output image
            ofname = os.path.join(self.img_output_dir, obasename)
            cv2.imwrite(ofname, bboxed_img)
            logger.debug(f'Wrote {ofname}')


    def apply(self, ann_fname: str) -> Tuple[Image_t, str]:
        '''Draw bboxes on an image.

        :returns: (image, output_basename)
        '''
        logger.info(f'Draw bbox on image: {ann_fname}')

        # Load JSON annotation and image of piece from local filesystem.
        ann: Annotation_t = json.load(open(ann_fname))
        image: Image_t = self.load_image(ann)

        logger.debug(f'annotation (h x w) = {ann["image_size"][0]["height"]} x {ann["image_size"][0]["width"]}')
        logger.debug(f'image (h x w) = {image.shape}')

        # Draw bbox image on a copy, and return it + img filename.
        bboxed_img = plot_img_with_bbox(image, ann)
        obasename = ann['file'].rsplit('/', 1)[-1]
        return bboxed_img, obasename


    def load_image(self, ann: Annotation_t) -> Image_t:
        '''Load a 3-channel image from local filesystem. This method will
        map the S3 path of each image piece to local dir indicated in
        `image_input_dir`.

        :param ann: piece annotation.
        '''
        local_img_fname: Path = self.img_input_dir / ann['file']
        image: Image_t = cv2.imread(str(local_img_fname), 1)
        return image


def plot_img_with_bbox(img: Image_t, d: Annotation_t):
    '''Draw bboxes on the copy of the original image.'''
    bboxed_img = img.copy()
    for i,bbox in enumerate(d['annotations']):
        # Get bbox coordinates
        x_min, y_min = bbox['left'], bbox['top']
        x_max, y_max = x_min + bbox['width'], y_min + bbox['height']

        # Workaround broken annotation and use red color. Otherwise, use green
        # color for good bboxes.
        if bbox['width'] < 0 or bbox['height'] < 0:

            logger.debug(f'Fixing bbox {i}...')
            ori_xmin, ori_ymin, ori_xmax, ori_ymax = x_min, y_min, x_max, y_max
            x_min, y_min = min(ori_xmin, ori_xmax), min(ori_ymin, ori_ymax)
            x_max, y_max = max(ori_xmin, ori_xmax), max(ori_ymin, ori_ymax)
            color = [0,0,255]   # Red bboxes
        else:
            color = [0,255,0]   # Green bboxes

        # Log info
        logger.debug(f'Bbox {i}: ({x_min}, {y_min}); ({x_max}, {y_max})')
        if (y_min > img.shape[0]
                or y_max > img.shape[0]
                or x_min > img.shape[1]
                or x_max > img.shape[1]):
            logger.warning(f'Bbox {i} is partially or wholly outside image.')

        # Draw the rectangles. Note that if bboxes wholly outside the image
        # are invisible.
        cv2.rectangle(bboxed_img, pt1=(x_min, y_min), pt2=(x_max, y_max),
                      color=color, thickness=2)
        cv2.putText(bboxed_img, f'{bbox["class_id"]}', (x_min+1,y_min+10), 1, 1, 255, 2)

    return bboxed_img



if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('img_output_dir', metavar='IMG_OUTPUT_DIR', help='Path to output images')
    parser.add_argument('-i', '--ann-input-dir', help='Path to input annotations', default='./train_annotation')
    parser.add_argument('-g', '--img-input-dir', help='Path to input images', default='./train')
    parser.add_argument('-v', '--verbose', help='Verbose/debug mode', default=False, action='store_true')
    args = parser.parse_args()

    # Display selected configurations
    logger.info(f'Annotation input dir: {args.ann_input_dir}')
    logger.info(f'Image input dir: {args.img_input_dir}')
    logger.info(f'Image output dir: {args.img_output_dir}')

    # Set verbosity of logs
    if args.verbose:
        logger.setLevel(logging.DEBUG)

    # Start grouping
    opts = vars(args)
    opts.pop('verbose')
    p = Bboxer(**opts)
    p.apply_all()
