#!/usr/bin/env python3

"""
A collection of utility functions for SageMaker GroundTruth's bounding box augmented manifest (i.e., the output).

Require recent version of s3fs to support filemode 'r' or 'w'.

>>> ClassMapConverter('s3://path/to/train.manifest', 's3://path/to/train2.manifest', gt_job='bounding-box').convert()
>>> ClassMapChecker('s3://path/to/train2.manifest', gt_job='bounding-box).check()
>>> BboxDistributionChecker('s3://path/to/train2.manifest', gt_job='bounding-box').check()
"""

from collections import Counter
from copy import deepcopy
import json
import s3fs
from typing import Any, List, Dict, Iterable, Tuple


class Item(object):
    """Represent a named item and the zone it occupies in the image."""
    def __init__(self, name:str, xmin: int, ymin: int, xmax: int, ymax: int):
        self.name = name
        self.xmin = xmin
        self.ymin = ymin
        self.xmax = xmax
        self.ymax = ymax

    def __contains__(self, pt):
        """Check whether point (x,y) is in this zone.
        
        :param pt: (x,y)
        """
        return (self.xmin <= pt[0] <= self.xmax) and (self.ymin <= pt[1] <= self.ymax)


class MultiZoneItem(object):
    def __init__(self, obj:str, name:str, zones: Iterable[Tuple[int, int, int, int]]):
        """Represent a named item and the zones it occupies in the image.
        
        :param zones: [(xmin, ymin, xmax, ymax), ...]
        """
        self.name = name
        self.items = [Item(name, *bbox) for bbox in zones]

    def __contains__(self, pt):
        """Check whether point (x,y) is in any of this item's zones. Complexity: O(N)."""
        for item in self.items:
            if pt in item:
                return True

        return False


#######################################################################################################################
# These global variables are for just to illustrate this class map converter.
# Change this to adapt to new needs.

object_states = ['light_on', 'light_off', 'tap_on', 'tap_off', 'fan_other']

# Assume disjoint zones!!
items = [
    Item('living_room_light', '', 350, 0, 654, 116),
    Item('mini_kitchen_water', 635, 225, 680, 275),
    MultiZoneItem('ceiling_fan', [(1080, 764, 1223,899), (1403, 724, 1475, 794)])
]

new_label_str = ['living_room_light light_on',
                 'living_room_light light_off',
                 'mini_kitchen_water tap_on',
                 'mini_kitchen_water tap_off',
                 'ceiling_fan fan_other']

new_labels = { s: str(i) for i,s in enumerate(new_label_str) }
#######################################################################################################################


class ClassMapChecker(object):
    DEFAULT = {
        'profile': 'default',      # AWS profile name.
        'gt_job': 'bounding-box'   # GroundTruth job name, to navigate the augmented manifest.
    }

    def __init__(self, ifname:str, **opts):
        """Check the class maps within an augmented manifest, to detect whether class_id are consistent across
        JSON lines (i.e., tasks).

        :param ifname: 's3://bucket/path/to/augmented.manifest' or '/local/dir/augmented.manifest'
        """
        self.ifname = ifname
        
        # Default setting
        for k,v in self.DEFAULT.items():
            setattr(self, k, v)

        # Override default setting
        for k,v in opts.items():
            setattr(self, k, v)

        # Eager authentication to S3
        if self.ifname.startswith('s3://') or self.ofname.startswith('s3://'):
            self.fs = s3fs.S3FileSystem(anon=False, profile_name=self.profile)
            self._open = self.fs.open
        else:
            self._open = open

    def check(self, sort=True) -> Dict[str, int]:
        """Check the augmented manifest.

        Raise FileNotFoundError if no input files found.

        :returns: dictionary {'class_id class_label': jsonline_count}
        """
        results = Counter()
        with self._open(self.ifname, 'rb') as f:
            for line_b in f:
                task = json.loads(line_b)
                for k,v in task[f'{self.gt_job}-metadata']['class-map'].items():
                    results[f'{k} {v}'] += 1
        if sort:
            results = {k: results[k] for k in sorted(results, key=lambda x: int(x.split(' ', 1)[0]))}
        return dict(results)


class BboxDistributionChecker(object):
    DEFAULT = {'profile': 'default', 'gt_job': 'bounding-box'}

    def __init__(self, ifname:str, **opts):
        """Check the distribution of bounding box types within an augmented manifest, to see how (un)balance the
        augmented manifest is in terms of bounding-box distributions.

        :param ifname: 's3://bucket/path/to/augmented.manifest' or '/local/dir/augmented.manifest'
        """
        self.ifname = ifname
        
        # Default setting
        for k,v in self.DEFAULT.items():
            setattr(self, k, v)

        # Override default setting
        for k,v in opts.items():
            setattr(self, k, v)

        # Eager authentication to S3
        if self.ifname.startswith('s3://') or self.ofname.startswith('s3://'):
            self.fs = s3fs.S3FileSystem(anon=False, profile_name=self.profile)
            self._open = self.fs.open
        else:
            self._open = open

    def check(self, sort=True) -> Dict[str, int]:
        """Check the augmented manifest.

        Raise FileNotFoundError if no input files found.

        :returns: dictionary {'class_id class_label': bbox_count}
        """
        results = Counter()
        with self._open(self.ifname, 'rb') as f:
            for line_b in f:
                task = json.loads(line_b)
                class_map = task[f'{self.gt_job}-metadata']['class-map']
                for bbox in task[f'{self.gt_job}']['annotations']:
                    class_id = str(bbox['class_id'])
                    klass = class_map[class_id]
                    results[f'{class_id} {klass}'] += 1
        if sort:
            results = {k: results[k] for k in sorted(results, key=lambda x: int(x.split(' ', 1)[0]))}
        return dict(results)


class ClassMapConverter(object):
    DEFAULT = {
        'profile': 'default',       # AWS profile (i.e., credential used for authentication)
        'gt_job': 'bounding-box',   # Name of GT job; needed to navigate augmented manifest
        'new_labels': new_labels,   # New class map
        'items': items              # Named items and their zone(s)
    }                                   

    def __init__(self, ifname:str, ofname:str, **opts):
        """Convert class map and bounding box's from "object_state" to "object_name object_state".
        
        :param ifname: 's3://bucket/path/to/augmented.manifest' or '/local/dir/augmented.manifest'
        """
        self.ifname = ifname
        self.ofname = ofname

        # Generic item.
        self.generic_item = oidutil.Item('generic', 0,0,0,0)

        # Default setting
        for k,v in self.DEFAULT.items():
            setattr(self, k, v)

        # Override default setting
        for k,v in opts.items():
            setattr(self, k, v)

        # Eager authentication to S3
        if self.ifname.startswith('s3://') or self.ofname.startswith('s3://'):
            self.fs = s3fs.S3FileSystem(anon=False, profile_name=self.profile)
            self._open_input = self.fs.open
        else:
            self._open_input = open

        # Function to create output augmented manifest file
        if self.ofname.startswith('s3://'):
            self._open_output = self.fs.open
        else:
            self._open_output = open

    def convert(self):
        """Convert all JSON lines in the input augmented file to an output file.

        Raise FileNotFoundError if no input files found.
        """
        with self._open_input(self.ifname, 'rb') as f_in:
            with self._open_output(self.ofname, 'w') as f_out:
                for line_b in f_in:
                    task = json.loads(line_b)
                    patched_task = self.convert_one(task)
                    f_out.write(json.dumps(patched_task))
                    f_out.write('\n')


    def convert_one(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """Convert bbox labels and class map of a single JSON line.

        The name to assign to each object_state belongs to the object whose zone (or one of its zones) encapsulates the
        bbox's centroid. It is assumed that zones never overlap with each other, otherwise this method will greedily
        pick the first matching object in `self.items`.
        
        To recap, here's the relevant fragment of an augmented manifest's JSON line::

            {
                "source-ref": "s3://path/to/images-01.jpg",
                "bounding-box": {
                    "annotations": [
                        {
                            "class_id": 0,
                            "width": 101,
                            "top": 795,
                            "height": 96,
                            "left": 1098
                        },
                        ...
                    ],
                    ...
                },
                "bounding-box-metadata": {
                    "job-name": "labeling-job/bounding-box",
                    "class-map": {
                        "0": "light_on",
                        "1": "light_off",
                        ...
                    },
                    ...
                }
            }

        :param task: a dictionary with the same structure as GT's output JSON line.
        :return: a dictionary with the same structure as task, but with updated bbox labels and class map.
        """
        result = deepcopy(task)
        old_class_map = result[f'{self.gt_job}-metadata']['class-map']
        old_bboxes: List[Dict[str, int]] = result[self.gt_job]['annotations']

        for bbox in old_bboxes:
            # Get the bounding coordinates
            x0, x1 = bbox['left'], bbox['left'] + bbox['width']
            y0, y1 = bbox['top'], bbox['top'] + bbox['height']

            # Compute centroid
            x, y = (x0 + x1)//2, (y0 + y1)//2

            # Get the matching named item
            for item in self.items:
                if (x,y) in item:
                    # Matching object id found
                    break
            else:
                # No matching object id, use 'generic' as name
                item = self.generic_item

            # Get old class
            old_class_id: str = str(bbox['class_id'])
            old_class: str = old_class_map[old_class_id]

            # New class. Remember to strip leading/trailing spaces, esp. for
            # named item with an empty-string name.
            new_class: str = f'{item.name} {old_class}'.strip()
            new_class_id: str = self.new_labels[new_class]
            #print(f'{old_class_id} {old_class} -> {new_class_id} {new_class}')

            # Patch the bbox's class_id
            bbox['class_id'] = new_class_id

        # Patch the class-map of this task
        result[f'{self.gt_job}-metadata']['class-map'] = {v:k for k,v in self.new_labels.items()}
        return result
